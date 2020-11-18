# Transform stuff from Mikel's Mail class into my PostgreSQL-ready clean data
require 'mail'
require 'date'
require 'net/smtp'

module MyMail
	class << self

		# email = hash with id, profile, their_email, subject, body, message_id, referencing
		# ms = hash of connection info, stored in core.configs
		def send(email, ms)
			msg =  "From: %s\n" % ms[:from]
			msg << "To: %s\n" % email[:their_email]
			msg << "Message-ID: <%s>\n" % email[:message_id]
			msg << "Date: %s\n" % Time.now.to_datetime.rfc2822
			msg << "Content-Type: text/plain; charset=UTF-8\n"
			msg << "Subject: %s\n" % email[:subject]
			if email[:referencing]
				msg << "References: <%s>\n" % email[:referencing]
				msg << "In-Reply-To: <%s>\n" % email[:referencing]
			end
			msg << "\n"
			msg << email[:body]
			if email[:reftext]
				msg << email[:reftext]
			end
			smtp = Net::SMTP.new(ms[:address], ms[:port])
			smtp.enable_starttls
			smtp.start(ms[:domain], ms[:user_name], ms[:password], :login) do |s|
				s.send_message msg, ms[:user_name], email[:their_email]
			end
		end

		# IN:
		# profile string : 'derek@sivers' or 'muckwork'
		# hash with address, port, user_name, password, enable_ssl
		# db = PG::Connection
		def import(profile, pop3_hash, db)
			Mail::Configuration.instance.retriever_method(:pop3, pop3_hash)
			what2find = {what: :first, count: 1, order: :asc, delete_after_find: true}
			mail = Mail.find(what2find)
			while mail != [] do
				puts mail.message_id + "\t" + mail.from[0]
				jsonemail = parse(mail, profile).to_json
				res = db.exec_params('SELECT * FROM peeps.import_email($1)', [jsonemail])
				unless res[0]['status'] == '200'
					puts res[0]['js']
				end
				mail = Mail.find(what2find)
			end
		end

		def attachments_dir
			'/var/www/htdocs/attachments/'
		end

		# IN:
		# mail = object from Mail class
		# profile string : 'derek@sivers' or 'muckwork'
		# RETURNS: hash of clean values for importing into database
		def parse(mail, profile)
			h = {profile: profile, category: profile}
			h[:message_id] = mail.message_id[0,255]
			h[:their_email] = mail.from[0][0,127].downcase
			h[:their_name] = their_name(mail)
			h[:subject] = (mail.subject.nil?) ? 'email' : mail.subject[0,127]
			h[:body] = body(mail)
			h[:headers] = headers(mail)
			h[:references] = references(mail)
			h[:attachments] = attachments(mail)
			h
		end

		def their_name(mail)
		begin
			# crashes when unknown encoding name
			full_from_line = mail[:from].decoded
		rescue
			full_from_line = mail[:from].value
		end
		begin
			# badly formatted 'From' (non-ASCII characters) crashes Address.new
			a = Mail::Address.new(full_from_line)
			if a.display_name
				return a.display_name[0,127]
			elsif a.name
				return a.name[0,127]
			else
				return mail.from[0][0,127]
			end
		rescue
			if /(.+)\s<\S+@\S+>/.match(full_from_line)
				return $1.gsub('"', '')
			else
				return full_from_line[0,127]
			end
		end
		end

		def body(mail)
			strip_tags = %r{</?[^>]+?>}
			unless mail.multipart?
				text = (mail.content_type =~ /html/i) ?
					mail.decoded.gsub(strip_tags, '') : mail.decoded
				return cleaned text
			end
			text = ''
			parts_with_ctype(mail.parts, 'text/plain').each do |p|
				text << p.decoded
			end
			if text == ''
				parts_with_ctype(mail.parts, 'text/html').each do |p|
					text << p.decoded.gsub(strip_tags, '')
				end
			end
			cleaned text
		end

		def headers(mail)
			begin
				s = mail.header.to_s
			rescue
				s = mail.header.raw_source
			end
			lines = []
			%w(to from message-id subject date in-reply-to references cc).each do |f|
				r = Regexp.new('^' + f + ':.*$', true)
				m = r.match(s)
				lines << m[0].strip if m
			end
			lines.join("\n")
		end

		# array of message_ids (if any) referenced in In-Reply-To: or References: headers
		def references(mail)
			res = []
			if mail.references
				Array(mail.references).each do |i|
					res.push(i) unless res.include?(i)
				end
			end
			if mail.in_reply_to
				Array(mail.in_reply_to).each do |i|
					res.push(i) unless res.include?(i)
				end
			end
			res
		end

		# NOTE: actually saves the binary files to the attachments_dir!
		def attachments(mail)
			res = []
			mail.attachments.each do |a|
				h = {}
				h[:mime_type] = a.content_type.split(';')[0]
				h[:filename] = our_filename_for a.filename
				filepath = attachments_dir + h[:filename]
				File.open(filepath, 'w+b', 0644) {|f| f.write a.body.decoded}
				h[:bytes] = FileTest.size(filepath)
				res << h
			end
			res
		end

		def cleaned(str)
			enc_opts = {invalid: :replace, undef: :replace, replace: ' '}
			begin
				str.strip.gsub("\r", '').encode('UTF-8', enc_opts).force_encoding('UTF-8')
			rescue
				enc = str.encoding
				str.force_encoding('BINARY')
				# remove bad UTF-8 characters here
				str.gsub!(0xA0.chr, '')
				str.gsub!(0x8A.chr, '')
				str.gsub!(0xC2.chr, '')
				str.force_encoding(enc)
				str.strip.gsub("\r", '').encode('UTF-8', enc_opts).force_encoding('UTF-8')
			end
		end

		def parts_with_ctype(partslist, content_type)
			res = []
			partslist.each do |p|
				if p.multipart?
					res << parts_with_ctype(p.parts, content_type)
				elsif p.content_type.downcase.include?(content_type) && (p.content_disposition =~ /attach/i).nil?
					res << p
				end
			end
			res.flatten
		end

		def our_filename_for(str)
			alpha = Range.new('a', 'z').to_a
			ourbit = Time.now.to_s[0,10].gsub('-', '')
			4.times { ourbit << alpha[rand(alpha.size)] }
			ourbit + '-' + str.gsub(/[^a-zA-Z0-9\-._]/, '')
		end

	end
end
