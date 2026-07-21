# Latent Variable Modelling — Quarto site

Real Quarto source (`.qmd` + `_quarto.yml`), not the HTML demo — open this folder as a project in RStudio and edit directly.

## To render

1. Install [Quarto](https://quarto.org) (bundled with recent RStudio) and, for full execution, the R packages referenced in the lectures (`lavaan`, `psych`).
2. Open this folder in RStudio (or `File → New Project → Existing Directory`).
3. Use the **Build** pane's "Render Website" button, or in the terminal:
   ```
   quarto preview
   ```
   ```
   quarto render
   ```
4. Output builds to `_site/`.

## Structure

- `_quarto.yml` — site config: sidebar nav, search, theme
- `styles.scss` — Modernist-inspired theme (Archivo, red accent, flat corners)
- `index.qmd` — home page
- `lectures/01-04*.qmd` — the four lectures
- `annexes/*.qmd` — formula reference, R function tutorial, annotated output
- `course-notes.qmd` — consolidated PDF handout (all lectures + annexes). Render with:
  ```
  quarto render course-notes.qmd --to pdf
  ```
  then rename/move the output to `course-notes.pdf` at the project root so the navbar's "Download PDF" link resolves (or update the href in `_quarto.yml`). Needs a LaTeX install (`quarto install tinytex` if you don't have one).

Code chunks are marked `eval: false` since they reference illustrative data (`items`, `lvm_data`) not included here — swap in real data and remove that flag to execute for real.
