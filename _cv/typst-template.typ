// CV layout for the PDF version of cv.qmd: a classic academic vita.
// Single column, serif, dates in a narrow left column, greyscale to match
// the website. Libertinus Serif ships inside Typst, so local and CI builds
// produce the same PDF.

#let cv-muted = luma(38%)
#let cv-rule = luma(75%)
#let cv-date-width = 6em

#let cv(
  name: none,
  tagline: none,
  contacts: (),
  updated: none,
  paper: "us-letter",
  font: ("Libertinus Serif",),
  fontsize: 10.5pt,
  body,
) = {
  // Quarto also applies the site's _brand.yml to this PDF; the `fill` and
  // heading `font` settings below undo its screen-only tinted page and fonts.
  set document(title: [#name — Curriculum Vitae])
  set text(font: font, size: fontsize, fill: black, lang: "en", number-type: "lining")
  set par(justify: false, leading: 0.58em, spacing: 0.9em)
  set list(indent: 0.2em, body-indent: 0.5em, marker: [–])

  set page(
    paper: paper,
    fill: none,
    margin: (x: 2cm, top: 1.6cm, bottom: 1.8cm),
    footer: context {
      set text(size: 8pt, fill: cv-muted)
      grid(
        columns: (1fr, auto, 1fr),
        align(left)[#name · CV],
        if updated != none [Updated #updated],
        align(right, counter(page).display("1 / 1", both: true)),
      )
    },
  )

  show link: set text(fill: black)
  show heading: set text(font: font, weight: "regular")

  // Quarto shifts headings up one level for Typst, so `##` in cv.qmd arrives
  // here as level 1 and `###` as level 2.
  // Sections: small caps with a hairline to the margin.
  show heading.where(level: 1): it => block(above: 1.3em, below: 0.75em, sticky: true)[
    #set text(size: 1.15em, tracking: 0.04em)
    #smallcaps(it.body)
    #box(width: 1fr, inset: (left: 0.5em), line(length: 100%, stroke: 0.4pt + cv-rule))
  ]
  // Subsections: italic, aligned with the entry bodies.
  show heading.where(level: 2): it => {
    set text(size: fontsize, style: "italic") // body size, so `em` matches the entry grid
    block(above: 1em, below: 0.65em, sticky: true, pad(left: cv-date-width + 1em, it.body))
  }

  // Header
  block(below: 1.6em)[
    #text(size: 2.1em, name)
    #if tagline != none {
      v(-0.4em)
      text(size: 1.05em, fill: cv-muted, tagline)
    }
    #v(0.1em)
    #text(size: 0.88em, contacts.join[#h(0.45em)·#h(0.45em)])
  ]

  body
}

// One CV line. Called from the shortcodes in _cv/cv.lua.
#let cv-entry(
  date: none,
  title: none,
  loc: none,
  description: none,
  body: none,
  details: (),
) = block(breakable: false, below: 0.65em, grid(
  columns: (cv-date-width, 1fr),
  column-gutter: 1em,
  text(fill: cv-muted, if date != none { date }),
  {
    set par(spacing: 0.35em)
    // Title wraps in its own column so the location stays on one line.
    if title != none or loc != none {
      grid(
        columns: (1fr, auto),
        column-gutter: 1em,
        if title != none { strong(title) },
        if loc != none { text(style: "italic", fill: cv-muted, loc) },
      )
    }
    if description != none { par(text(fill: cv-muted, description)) }
    if body != none { par(body) }
    if details.len() > 0 {
      v(0.15em)
      list(..details)
    }
  },
))
