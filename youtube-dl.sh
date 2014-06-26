#!/bin/sh -e

read request

while /bin/true; do
  read header
  [ "$header" = "`printf '\r'`" ] && break
done

code="${request#GET /}"
code="${code% HTTP/*}"

urldecode() { echo -n $1 | sed 's/%\([0-9A-F]\{2\}\)/\\\\\\\x\1/gI' | xargs printf; }

qualityisgreater() {
  if [ "$1" = "hd1080" ] && [ "$2" != "hd1080" ]; then
    return 0
  elif [ "$2" = "hd1080" ]; then
    return 1
  elif [ $1 = "hd720" ] && [ "$2" != "hd720" ]; then
    return 0
  elif [ "$2" = "hd720" ]; then
    return 1
  elif [ $1 = "large" ] && [ "$2" != "large" ]; then
    return 0
  elif [ "$2" = "large" ]; then
    return 1
  elif [ $1 = "medium" ] && [ "$2" != "medium" ]; then
    return 0
  elif [ "$2" = "medium" ]; then
    return 1
  fi
  return 1
}

cookiejar=`mktemp`
baseurl="http://www.youtube.com/get_video_info?video_id=$code&el=detailpage&ps=default&eurl=&gl=US&hl=en"
data=`curl --silent --cookie-jar "$cookiejar" "$baseurl"`

highestquality=small
highesturl=""
highesttype=video/x-flv
title=""
for part in `echo $data | tr '&' ' '`; do
  key=`echo $part | cut -d"=" -f1`
  value=`echo $part | cut -d"=" -f2`
  if [ "$value" != "" ]; then
    value=`urldecode "$value"`
  fi
  case "$key" in
  "url_encoded_fmt_stream_map")
    for format in `echo $value | tr ',' ' '`; do
      for part in `echo $format | tr '&' ' '`; do
        key=`echo $part | cut -d"=" -f1`
        value=`echo $part | cut -d"=" -f2`
        if [ "$value" != "" ]; then
          value=`urldecode "$value"`
        fi
        case "$key" in
        "url")
          url=$value;;
        "quality")
          quality=$value;;
        "fallback_host")
          fallback_host=$value;;
        "type")
          type=$value;;
        "itag")
          itag=$value;;
        esac
      done
      if [ $quality = $highestquality ]; then
        if [ $type = "video/webm" ]; then
          highesttype=$type
          highesturl=$url
          highestquality=$quality
	elif [ $type = "video/mp4" ] && [ $highesttype != "video/webm" ]; then
          highesttype=$type
          highesturl=$url
          highestquality=$quality
	fi
      elif qualityisgreater $quality $highestquality; then
        highesttype=$type
        highesturl=$url
        highestquality=$quality
      fi
    done ;;
  "title") title="$value" ;;
  esac
done

if [ "$highesturl" = "" ]; then
  echo "fail $code" >&2
  echo HTTP/1.1 200 OK
  echo Content-Type: text/plain
  echo
  echo "error :("
else
  url=`curl --silent --head --output /dev/null --write-out %{redirect_url} --cookie "$cookiejar" "$highesturl"`

  while [ "$url" != "" ]; do
    highesturl=$url
    url=`curl --silent --head --output /dev/null --write-out %{redirect_url} --cookie "$cookiejar" "$highesturl"`
  done

  echo "success $code" >&2

  curl --silent --include --cookie "$cookiejar" "$highesturl"
fi

rm $cookiejar
