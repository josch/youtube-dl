#!/usr/bin/env python
# -*- coding: utf-8 -*-

__author__ = "J. Schauer <josch@pyneo.org>"
__version__ = "prototype"
__copyright__ = "Copyright (c) 2010 J. Schauer"
__license__ = "AGPLv3"

from imp import load_source
youtube = load_source('youtube', '/usr/bin/youtube-dl')

for elm in ['YoutubeIE', 'MetacafeIE', 'DailymotionIE', 'YoutubePlaylistIE',
	'YoutubeUserIE', 'YoutubeSearchIE', 'GoogleIE', 'GoogleSearchIE',
	'PhotobucketIE', 'YahooIE', 'YahooSearchIE', 'GenericIE',
	'FileDownloader', 'PostProcessor']:
	globals()[elm] = getattr(youtube, elm)
del youtube

FileDownloader.process_info = lambda self, info_dict : setattr(self, 'info_dict', info_dict)

import urllib2
from urllib import splittype, splithost

def getytdlurl(ytid):
	youtube_ie = YoutubeIE()
	metacafe_ie = MetacafeIE(youtube_ie)
	dailymotion_ie = DailymotionIE()
	youtube_pl_ie = YoutubePlaylistIE(youtube_ie)
	youtube_user_ie = YoutubeUserIE(youtube_ie)
	youtube_search_ie = YoutubeSearchIE(youtube_ie)
	google_ie = GoogleIE()
	google_search_ie = GoogleSearchIE(google_ie)
	photobucket_ie = PhotobucketIE()
	yahoo_ie = YahooIE()
	yahoo_search_ie = YahooSearchIE(yahoo_ie)
	generic_ie = GenericIE()

	fd = FileDownloader({
		'username': None,
		'password': None,
		'format': None,
		'quiet': True,
		'simulate': True,
		'ignoreerrors': False
		})

	fd.add_info_extractor(youtube_search_ie)
	fd.add_info_extractor(youtube_pl_ie)
	fd.add_info_extractor(youtube_user_ie)
	fd.add_info_extractor(metacafe_ie)
	fd.add_info_extractor(dailymotion_ie)
	fd.add_info_extractor(youtube_ie)
	fd.add_info_extractor(google_ie)
	fd.add_info_extractor(google_search_ie)
	fd.add_info_extractor(photobucket_ie)
	fd.add_info_extractor(yahoo_ie)
	fd.add_info_extractor(yahoo_search_ie)
	retcode = fd.download((
		ytid,
		))
	if retcode:
		return
	u = fd.info_dict['url'].encode('UTF-8', 'xmlcharrefreplace') # title, url, thumbnail, description
	opener = urllib2.build_opener()
	f = opener.open(urllib2.Request(u))
	_, rest = splittype(f.url)
	host, path = splithost(rest)
	return (host, path,
		fd.info_dict['stitle'].encode('UTF-8', 'xmlcharrefreplace'),
		fd.info_dict['id'].encode('UTF-8', 'xmlcharrefreplace'),
		fd.info_dict['ext'].encode('UTF-8', 'xmlcharrefreplace'))

if __name__ == '__main__':
	getytdlurl('gR4OM5tmzno')
