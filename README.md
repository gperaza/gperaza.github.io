# gperaza.github.io

Personal academic website, built with [Quarto](https://quarto.org) and published to
GitHub Pages at **https://gonzalo-peraza.com** (repo `gperaza/gperaza.github.io`).

The design blends two references: the warm-paper, low-energy restraint of
[Low Tech Magazine](https://solar.lowtechmagazine.com) and the serif editorial
typography of [Works in Progress](https://www.worksinprogress.co). All colors and
fonts live in **`_brand.yml`**; the editorial CSS refinements live in **`theme.scss`**.

## Preview locally

Requires Quarto (already installed here: `quarto --version`).

```bash
quarto preview      # live-reloading local server
quarto render       # one-off full build into _site/
```

## Structure

| Path | What it is |
|------|-----------|
| `_quarto.yml` | Site config: navbar, footer, HTML format options |
| `_brand.yml` | Colors + fonts (single source of truth) |
| `theme.scss` | Editorial CSS (drop caps, side notes, dither, rules) |
| `index.qmd` | About / landing page (Quarto `about` block) |
| `cv.qmd` + `_cv/` | CV, rendered to both a web page and `cv.pdf` (see below) |
| `research.qmd`, `teaching.qmd`, `talks.qmd`, `software.qmd` | Pages that pull their lists (projects, courses, supervision, talks, media, software) from `_cv/cv.yml` |
| `publications.qmd` + `references.bib` | Publication list, generated from the BibTeX file (also feeds the CV) |
| `blog.qmd` + `posts/` | Blog listing + posts (one folder per post) |
| `assets/` | Images, favicon |
| `scripts/dither.sh` | Optional image-dithering helper |
| `.github/workflows/publish.yml` | CI: render + deploy to Pages |

## Still to do

- **`assets/img/favicon.svg`** → your favicon (optional).
- **`posts/welcome/`** is a sample post showing the design; replace or delete it.
- **ICUH 2026 talk title** → placeholder in `_cv/cv.yml` (`talks`).

## Writing content

- **New blog post:** copy `posts/welcome/` to `posts/<slug>/`, edit `index.qmd`.
- **New talk, course, project, or software entry:** add it to the matching list in
  `_cv/cv.yml`; it shows up on the CV and on the Talks/Teaching/Research/Software pages.
- **New publication:** add its BibTeX entry to `references.bib`.
- **Drop cap:** wrap the first paragraph in `::: {.dropcap}` … `:::`.
- **Side notes:** just write a footnote (`^[...]`) — it renders in the margin.
- **Dithered image:** add `{.dither}` to an image, or pre-process it with
  `scripts/dither.sh` for true (smaller) dithering.

## Deploy

1. Push this repo to `main` on GitHub.
2. In the repo: **Settings → Pages → Build and deployment → Source = "GitHub Actions"**.
3. Every push to `main` runs `.github/workflows/publish.yml`, which renders the site
   and deploys it. No build artifacts are committed (`/_site` is git-ignored).

## CV

One source, two outputs: `quarto render` turns `cv.qmd` into the CV web page and
`cv.pdf` (via Typst, which ships with Quarto, so there is nothing else to install).

| File | What to edit |
|------|-------------|
| `_cv/cv.yml` | Header (name, tagline, contact links) and every section's entries |
| `references.bib` | Publications, listed newest first, with your name in bold |
| `cv.qmd` | Section order and headings; each section is one `{{< cv name >}}` shortcode |
| `_cv/typst-template.typ` | PDF layout (fonts, margins, spacing, paper size) |
| `_cv/cv.lua` | The shortcodes that turn the data into HTML or Typst |
| `theme.scss` (CV rules) | Web layout of the CV entries |

To add a section, add a list under `cv:` in `_cv/cv.yml`, then a `## Heading` and
`{{< cv name >}}` in `cv.qmd`. `quarto preview cv.qmd --to typst` previews the PDF.

## Optional upgrades

- **Self-host fonts** (fully offline / lowest energy): download the Newsreader &
  IBM Plex Mono `.woff2` files into `assets/fonts/`, declare `@font-face` in
  `theme.scss`, and drop `source: google` from `_brand.yml`.
- **Citation style:** add a `csl:` field to `publications.qmd`
  (see the [Zotero style repo](https://www.zotero.org/styles)).
- **Dark mode** is already on (a light/dark toggle appears in the navbar); remove the
  `dark:` block in `_quarto.yml`'s `theme:` to make the site light-only.
