#!/usr/bin/env python3

from mutagen.mp4 import MP4

print('---')

import os
import glob

# Fixes graphic audio title being gibberish

# Not sure why, but their actual title is stored as "album"
# while the title field is set to some internal identifier

# TODO: read zip from GA, fix title and filename automatically and dump to NAS

for filename in glob.iglob("/Volumes/dropbox/Archive/Audiobooks/Graphic Audio/*.m4b"):
  with open(filename, "rb+") as m4b:
    book = MP4(m4b)
    bookName = book.get('©alb')
    print("[BOOK] " + str(book.get('©alb')))
    if book['©nam'] != book.get('©alb'):
      book['©nam'] = book.get('©alb')
      book.save(m4b)
    else:
      print("Already Matches")

  # os.rename(filename, bookName)
  print("---")

exit(0)

# with open("./BMR1.m4a", "rb+") as f:
#   file = MP4(f)
#   # tags: mp4.MP4Tags = file.tags
#   print(file.get('©nam'))
#   print(file.keys())
#   for i in file.keys():
#     x = file.get(i)
#     if isinstance(x, list):
#       x2 = x[0]
#       if isinstance(x2, int):
#         print(x2)
#       else:
#         print(x2[0:25])
#     else:
#       print(x)
  # file['©nam'] = file.get('©alb')
  # file.save(f)
  # with open("output.m4a", 'wb+') as o:
  #     file.save(o)
