#import "@preview/pergamon:0.8.0" as pergamon
#import "@preview/pergamon:0.8.0": add-bib-resource, alphabetic-style, authoryear-style, cite, numeric-style

#let form-version = toml("typst.toml").tool.dfg-project-proposal.form-version

#let form-header(max-pages) = context {
  set text(size: 8.5pt)
  grid(
    columns: (1fr, 1fr),
    [DFG form 53.01 – #form-version], align(right)[page #counter(page).get().first() of max. #max-pages],
  )
}

/// Prints the bibliography at `size` (DFG allows down to 9pt) instead of
/// body text size, without pergamon's default title (the DFG form's own
/// heading covers that).
#let print-bibliography(size: 11pt, title: none, ..args) = {
  set text(size: size)
  pergamon.print-bibliography(title: title, ..args)
}

#let emphasis-defaults = state(
  "dfg-project-proposal-emphasis-defaults",
  (fill: rgb("#1F4E79"), weight: "bold"),
)

/// Changes `emphasize`'s defaults from here on, merging rather than replacing.
#let set-emphasis-defaults(..args) = emphasis-defaults.update(it => it + args.named())

/// Emphasizes `body`, e.g. an applicant's own work in the "list of
/// publications" section, or any other text worth calling out in the
/// project description.
#let emphasize(body, ..args) = context {
  let opts = emphasis-defaults.get() + args.named()
  text(..opts, body)
}

// Numeric citations compacted into ranges (e.g. [1-3, 5]); references
// typeset ACS-like (authors "Last, F.; Last, F.", bold year, italic volume).
#let acs-style = {
  let is-highlighted(reference) = reference.fields.at("keywords", default: "").contains("HIGHLIGHT")

  // Reused so the highlighted label ("[n]") matches the un-highlighted one.
  let default-reference-label = pergamon.format-citation-numeric(compact: true).reference-label

  let base = numeric-style(
    citation: (compact: true),
    reference: (
      print-doi: true,
      name-format: "{family}, {g}.",
      list-middle-delim: "; ",
      list-end-delim-two: "; ",
      list-end-delim-many: "; ",
      format-quotes: it => it,
      bibstring: ("in": none, "pages": none, "page": none),
      format-fields: (
        doi: (default, value, reference, field, options, style) => [
          DOI:~#link("https://doi.org/" + value, value)
        ],
      ),
      highlight: (rendered-reference, reference, index) => {
        if is-highlighted(reference) {
          emphasize(rendered-reference)
        } else {
          rendered-reference
        }
      },
      reference-label: (index, reference) => {
        let lbl = default-reference-label(index, reference)
        if is-highlighted(reference) {
          emphasize(lbl)
        } else {
          lbl
        }
      },
      format-functions: (
        journal-issue-title: (reference, options) => {
          let printfield = pergamon.pergamon-dev.printfield
          let journal = printfield(reference, "journaltitle", options)
          if journal == none {
            none
          } else {
            let formatted-journal = (options.format-journaltitle)(journal)
            let raw-year = printfield(reference, "parsed-date", options)
            let year = if raw-year == none { none } else { strong(raw-year) }
            let volume = if "volume" in reference.fields { emph(reference.fields.volume) } else { none }
            pergamon.commas(pergamon.spaces(formatted-journal, year), volume)
          }
        },
      ),
    ),
  )
  let base-citation-style = base.citation-style
  let sort-key(x) = if type(x) == str { float.inf } else { x.at(1).reference.label.at(0) }
  (
    base
      + (
        citation-style: (reference-dicts, form, options) => base-citation-style(
          reference-dicts.sorted(key: sort-key),
          form,
          options,
        ),
      )
  )
}

/// Sets up part 1 of a DFG project proposal (form 53.01) and the title
/// block. Apply with `#show: project-title.with(applicants: (...), title:
/// [...])`, then write sections 1-3 directly.
///
/// - applicants (array): One entry per applicant, e.g. `([First Last, City],)`.
/// - bibliography-style (dictionary): A pergamon style, e.g. `acs-style`
///   (the default), `alphabetic-style()`, or `authoryear-style()`.
#let project-title(applicants: (), title: [], bibliography-style: acs-style, body) = {
  set text(font: "Helvetica", size: 11pt, lang: "en", hyphenate: true)
  set heading(numbering: "1.1.1.1")
  set par(justify: true)
  show heading: set text(size: 11pt)
  show heading: set block(above: 1.5em, below: 1.5em)

  set page(
    paper: "a4",
    margin: (top: 2.5cm, bottom: 1.5cm, left: 2.5cm, right: 2cm),
    header: form-header(17),
  )

  heading(numbering: none, outlined: false)[Project Description -- Project Proposals]
  heading(numbering: none, outlined: false)[#applicants.join(linebreak())]
  heading(numbering: none, outlined: false)[#title]
  line(length: 100%, stroke: 0.5pt)
  heading(numbering: none, outlined: false)[Project Description]

  pergamon.refsection(style: bibliography-style)[#body]
}

/// Starts part 2: page break, page numbering reset, new header. Apply with
/// `#show: start-supplementary-information` right before section 4. Paper
/// size and margin carry over from `project-title`'s `set page` -- only the
/// header (page-limit count) changes here.
#let start-supplementary-information(body) = {
  counter(page).update(0)
  pagebreak()
  set page(header: form-header(8))

  body
}
