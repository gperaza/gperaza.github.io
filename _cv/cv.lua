-- Shortcodes for cv.qmd. Each renders the same data two ways: as HTML divs
-- (styled by the "CV" rules in theme.scss) or as calls to `cv-entry` in
-- _cv/typst-template.typ for the PDF.
--
--   {{< cv experience >}}        entries from the `cv.experience` list in _cv/cv.yml
--   {{< cv-pubs references.bib types="article-journal" me="Peraza" >}}
--                                BibTeX entries, newest first; `types` filters by
--                                CSL type, `me` bolds the author whose family name
--                                contains it.

local stringify = pandoc.utils.stringify

local MAX_AUTHORS = 8 -- longer author lists are cut to the first three + yours + "et al."

local function as_inlines(v)
  if v == nil then return nil end
  local t = pandoc.utils.type(v)
  if t == "Inlines" then return v end
  if t == "Blocks" then return pandoc.utils.blocks_to_inlines(v) end
  return pandoc.Inlines(stringify(v))
end

-- Inline content as a Typst content block, e.g. `[Some *text*]`, or `none`.
local function typst(ils)
  if ils == nil or #ils == 0 then return "none" end
  local s = pandoc.write(pandoc.Pandoc({ pandoc.Plain(ils) }), "typst")
  return "[" .. (s:gsub("%s+$", "")) .. "]"
end

-- One CV line: date column + title/location, description, plain body text,
-- and bullet details.
local function entry(e)
  local details = e.details or {}

  if quarto.doc.is_format("typst") then
    local ds = {}
    for _, d in ipairs(details) do ds[#ds + 1] = typst(d) .. "," end
    return pandoc.RawBlock("typst", string.format(
      "#cv-entry(date: %s, title: %s, loc: %s, description: %s, body: %s, details: (%s))",
      typst(e.date), typst(e.title), typst(e.location), typst(e.description),
      typst(e.body), table.concat(ds, " ")))
  end

  local body = pandoc.Blocks({})
  if e.title or e.location then
    local head = pandoc.Inlines({})
    if e.title then head:insert(pandoc.Strong(e.title)) end
    if e.location then head:insert(pandoc.Span(e.location, { class = "cv-location" })) end
    body:insert(pandoc.Div(pandoc.Plain(head), { class = "cv-head" }))
  end
  if e.description then body:insert(pandoc.Div(pandoc.Plain(e.description), { class = "cv-desc" })) end
  if e.body then body:insert(pandoc.Div(pandoc.Plain(e.body), { class = "cv-text" })) end
  if #details > 0 then
    local items = {}
    for _, d in ipairs(details) do items[#items + 1] = { pandoc.Plain(d) } end
    body:insert(pandoc.BulletList(items))
  end
  return pandoc.Div({
    pandoc.Div(pandoc.Plain(e.date or {}), { class = "cv-date" }),
    pandoc.Div(body, { class = "cv-body" }),
  }, { class = "cv-entry" })
end

local function section(args, _, meta)
  local name = stringify(args[1])
  local items = meta.cv and meta.cv[name]
  if not items then
    quarto.log.warning("cv: no section '" .. name .. "' under `cv:` in _cv/cv.yml")
    return pandoc.Blocks({})
  end
  local out = pandoc.Blocks({})
  for _, item in ipairs(items) do
    local details = {}
    for _, d in ipairs(item.details or {}) do details[#details + 1] = as_inlines(d) end
    out:insert(entry({
      date = as_inlines(item.date),
      title = as_inlines(item.title),
      location = as_inlines(item.location),
      description = as_inlines(item.description),
      details = details,
    }))
  end
  return out
end

-- "Gonzalo G." → "G. G."; lowercase particles ("de", "los") are dropped.
local function initials(given)
  local out = {}
  for word in stringify(given):gmatch("%S+") do
    local first = word:match(utf8.charpattern)
    if first and not first:match("^%l$") then out[#out + 1] = first .. "." end
  end
  return table.concat(out, " ")
end

local function author_list(authors, me)
  local names, mine = {}, nil
  for i, a in ipairs(authors) do
    local parts = {}
    if a.given then parts[#parts + 1] = initials(a.given) end
    for _, k in ipairs({ "dropping-particle", "non-dropping-particle" }) do
      if a[k] then parts[#parts + 1] = stringify(a[k]) end
    end
    parts[#parts + 1] = stringify(a.family or a.literal or "")
    local name = pandoc.Inlines(table.concat(parts, " "))
    if me and stringify(a.family or ""):find(me, 1, true) then
      mine = i
      name = pandoc.Inlines({ pandoc.Strong(name) })
    end
    names[i] = name
  end

  local shown, etal = names, false
  if #names > MAX_AUTHORS then
    shown, etal = { names[1], names[2], names[3] }, true
    if mine and mine > 3 then
      shown[#shown + 1] = pandoc.Inlines("…")
      shown[#shown + 1] = names[mine]
    end
  end

  local out = pandoc.Inlines({})
  for i, n in ipairs(shown) do
    if i > 1 then
      if etal or #shown > 2 then out:insert(pandoc.Str(",")) end
      out:insert(pandoc.Space())
      if i == #shown and not etal then out:extend({ pandoc.Str("and"), pandoc.Space() }) end
    end
    out:extend(n)
  end
  if etal then out:extend(pandoc.Inlines(", et al.")) end
  return out
end

-- Authors. Title. *Journal* vol(issue), page. doi:…
local function citation(r, me)
  local out = author_list(r.author or {}, me)
  if not stringify(out):match("%.$") then out:insert(pandoc.Str(".")) end
  out:insert(pandoc.Space())
  out:extend(r.title or {})
  if not stringify(r.title or ""):match("[%.%?!]$") then out:insert(pandoc.Str(".")) end

  local venue = pandoc.Inlines({})
  if r["container-title"] then
    venue:insert(pandoc.Emph(r["container-title"]))
    if r.volume then venue:extend({ pandoc.Space(), pandoc.Str(stringify(r.volume)) }) end
    if r.issue then venue:insert(pandoc.Str("(" .. stringify(r.issue) .. ")")) end
    if r.page then venue:extend({ pandoc.Str(","), pandoc.Space(), pandoc.Str(stringify(r.page)) }) end
  elseif r.publisher then
    venue:extend(r.publisher)
  end
  if #venue > 0 then
    out:insert(pandoc.Space())
    out:extend(venue)
    out:insert(pandoc.Str("."))
  end

  if r.doi then
    local doi = stringify(r.doi)
    out:insert(pandoc.Space())
    out:insert(pandoc.Link("doi:" .. doi, "https://doi.org/" .. doi))
  end
  return out
end

local function publications(args, kwargs)
  local path = stringify(args[1])
  local root = quarto.project.directory
  if root and not pandoc.path.is_absolute(path) then path = pandoc.path.join({ root, path }) end
  local f = io.open(path, "r")
  if not f then
    quarto.log.warning("cv-pubs: cannot open " .. path)
    return pandoc.Blocks({})
  end
  local refs = pandoc.read(f:read("a"), "bibtex").meta.references or {}
  f:close()

  local types
  local wanted = stringify(kwargs.types or "")
  if wanted ~= "" then
    types = {}
    for t in wanted:gmatch("[^,%s]+") do types[t] = true end
  end
  local me = stringify(kwargs.me or "")
  if me == "" then me = nil end

  local list = {}
  for i, r in ipairs(refs) do
    if not types or types[stringify(r.type or "")] then
      list[#list + 1] = { ref = r, i = i, year = tonumber(stringify(r.issued or ""):match("%d%d%d%d")) or 0 }
    end
  end
  table.sort(list, function(a, b)
    if a.year ~= b.year then return a.year > b.year end
    return a.i < b.i
  end)

  local out = pandoc.Blocks({})
  for _, p in ipairs(list) do
    out:insert(entry({
      date = p.year > 0 and pandoc.Inlines(tostring(p.year)) or nil,
      body = citation(p.ref, me),
    }))
  end
  return out
end

return {
  ["cv"] = section,
  ["cv-pubs"] = publications,
}
