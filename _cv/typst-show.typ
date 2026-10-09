#show: cv.with(
$if(cv.name)$
  name: [$cv.name$],
$endif$
$if(cv.tagline)$
  tagline: [$cv.tagline$],
$endif$
$if(cv.contacts)$
  contacts: ($for(cv.contacts)$[$it$], $endfor$),
$endif$
$if(date)$
  updated: [$date$],
$endif$
$if(papersize)$
  paper: "$papersize$",
$endif$
)
