# if I ever need to convert these to 2550x3300:
for i in we14cover-*.jpg ; do n=we14cover-2550x3300-$i.jpg; convert we14cover-$i.jpg -crop 1510x1955+22+545 -resize 2550x3300 we14cover-2550x3300-$i.jpg ; done
