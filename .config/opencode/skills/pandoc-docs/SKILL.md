---
name: pandoc-docs
description: "Create formatted documents with pandoc and upload to Google Drive."
license: MIT
compatibility: opencode
metadata:
  audience: agents
  domain: documents
  requires:
    bins: ["pandoc", "gws"]
---

# pandoc-docs

Create professional documents from markdown using pandoc, then upload to Google Drive.

## When to use this skill

- User asks you to create a document, RFC, report, technical analysis, or any formatted written deliverable
- User asks to export content to DOCX, PDF, or PPTX
- User asks to upload a document to Google Drive

## Workflow

### 1. Write content as markdown

Write the document content to a temporary `.md` file. Use standard markdown with pandoc extensions:

```markdown
---
title: "Document Title"
author: "Author Name"
date: "2026-04-13"
---

# First Section

Body text with **bold** and *italic*.

| Column A | Column B |
|----------|----------|
| data     | data     |
```

The YAML frontmatter block sets document metadata (title page, headers/footers).

### 2. Choose output format

| Document Type | Format | Extension | Notes |
|---------------|--------|-----------|-------|
| RFC / Technical doc | DOCX | `.docx` | Auto-converts to Google Docs on upload |
| Report / Analysis | DOCX | `.docx` | Best for collaborative editing |
| Presentation | PPTX | `.pptx` | Slide per `##` heading |
| Printable / Archival | PDF | `.pdf` | Requires LaTeX (`pdflatex` or `xelatex`) |
| Web / Email | HTML | `.html` | Standalone with embedded CSS |

**DOCX is the default choice** — Google Drive converts it to a native Google Doc automatically, preserving headings, tables, lists, and basic formatting.

### 3. Convert with pandoc

#### DOCX (default — for Google Docs)

```bash
pandoc input.md \
  -o output.docx \
  --reference-doc=SKILL_DIR/reference/esper-reference.docx \
  --from=markdown+smart+pipe_tables+yaml_metadata_block \
  --to=docx \
  --toc \
  --number-sections
```

The `--reference-doc` applies consistent Esper styling (fonts, margins, heading colors). Omit `--toc` and `--number-sections` for short documents.

Replace `SKILL_DIR` with the actual resolved path to this skill's base directory (shown at the bottom of the loaded skill content).

#### PDF (when printable output is needed)

```bash
pandoc input.md \
  -o output.pdf \
  --from=markdown+smart+pipe_tables+yaml_metadata_block \
  --pdf-engine=pdflatex \
  -V geometry:margin=1in \
  -V fontsize=11pt \
  --toc \
  --number-sections
```

If `pdflatex` is not available, convert to DOCX instead and let the user export to PDF from Google Docs.

#### PPTX (presentations)

```bash
pandoc input.md \
  -o output.pptx \
  --from=markdown+smart+pipe_tables+yaml_metadata_block \
  --slide-level=2
```

Each `##` heading starts a new slide. Use `---` for manual slide breaks.

#### HTML (standalone web page)

```bash
pandoc input.md \
  -o output.html \
  --from=markdown+smart+pipe_tables+yaml_metadata_block \
  --to=html5 \
  --standalone \
  --toc \
  --number-sections \
  --css=SKILL_DIR/reference/github.css
```

### 4. Upload or update on Google Drive

#### First upload (creates a new file)

```bash
gws drive +upload ./output.docx --name "RFC - Feature Name.docx"
gws drive +upload ./output.docx --parent FOLDER_ID
```

The response includes the file `id`. **Save this ID** — you need it to update the same file later.

#### Update an existing file (same link, new content)

```bash
gws drive files update \
  --params '{"fileId": "EXISTING_FILE_ID"}' \
  --upload ./output.docx
```

This replaces the content of the existing file in-place. The file ID, sharing settings, and Google Docs link all stay the same. Always prefer updating over creating a new upload when revising a document.

> [!CAUTION]
> Confirm with the user before uploading or updating. Show the filename and destination.

### 5. Get the Google Docs link

After upload, the response includes the file ID. Build the link:

- Google Docs: `https://docs.google.com/document/d/FILE_ID/edit`
- Google Slides: `https://docs.google.com/presentation/d/FILE_ID/edit`
- Drive file: `https://drive.google.com/file/d/FILE_ID/view`

For DOCX files, Google Drive auto-converts to Docs format. The `/edit` link opens the editable Google Doc.

> [!TIP]
> When working on a document iteratively, save the file ID after the first upload and use `files update` for all subsequent revisions. This keeps a single stable link throughout the editing process.

## Pandoc markdown tips

### Tables

Use pipe tables (the `pipe_tables` extension is enabled):

```markdown
| Feature | Status | Notes |
|---------|--------|-------|
| Auth    | Done   | OAuth2 |
| API     | WIP    | v2 endpoints |
```

### Code blocks

Use fenced code blocks with language hints:

````markdown
```python
def hello():
    print("world")
```
````

### Definition lists

```markdown
Term
:   Definition text here.
```

### Page breaks (DOCX/PDF only)

Force a page break in DOCX output:

```markdown
\newpage
```

### Images

```markdown
![Caption text](path/to/image.png){ width=80% }
```

### Metadata for title page

The YAML frontmatter generates a title page in DOCX and PDF:

```yaml
---
title: "RFC: Feature Name"
subtitle: "Esper Engineering"
author: "Author Name"
date: "April 2026"
abstract: |
  Brief summary of the document purpose and scope.
---
```

## Common recipes

### RFC / Design Document

```bash
# Write content
cat > /tmp/rfc.md << 'CONTENT'
---
title: "RFC: Feature Name"
subtitle: "Esper Engineering"
author: "Author Name"
date: "April 2026"
---

# Problem Statement
...

# Proposed Solution
...

# Alternatives Considered
...

# Implementation Plan
...
CONTENT

# Convert
pandoc /tmp/rfc.md -o /tmp/rfc.docx \
  --reference-doc=SKILL_DIR/reference/esper-reference.docx \
  --from=markdown+smart+pipe_tables+yaml_metadata_block \
  --toc --number-sections

# First time: upload and save the file ID
gws drive +upload /tmp/rfc.docx --name "RFC - Feature Name.docx"
# Returns {"id": "FILE_ID", ...}

# Subsequent revisions: update in place (same link)
gws drive files update --params '{"fileId": "FILE_ID"}' --upload /tmp/rfc.docx
```

### Technical Analysis

Same as RFC but typically without `--toc` for shorter documents. Include tables, code blocks, and diagrams.

### Sprint Report

Short document, no TOC, no numbered sections:

```bash
pandoc /tmp/report.md -o /tmp/report.docx \
  --reference-doc=SKILL_DIR/reference/esper-reference.docx \
  --from=markdown+smart+pipe_tables+yaml_metadata_block
```

## Bundled reference files

| File | Purpose |
|------|---------|
| `reference/esper-reference.docx` | DOCX reference template with Esper styling (fonts, margins, heading colors) |

## Troubleshooting

- **"Unknown output format"**: Check the file extension matches a supported pandoc format
- **No title page in DOCX**: Ensure the YAML frontmatter is at the very top of the file, preceded by `---` and followed by `---`
- **Tables not rendering**: Ensure you're using `pipe_tables` extension (included in the `--from` flag above)
- **Missing `pdflatex`**: Fall back to DOCX and let the user export to PDF from Google Docs
- **Upload fails**: Run `gws auth login` to refresh OAuth credentials
