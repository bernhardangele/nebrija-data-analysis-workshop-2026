# Makefile for Nebrija Data Analysis Workshop 2026 Quarto Presentations
#
# Commands:
#   make all       - Render all presentation slides (Session 1 & 2)
#   make session1  - Render Session 1 (lme4 mixed-effects models)
#   make session2  - Render Session 2 (brms Bayesian models)
#   make clean     - Clean up generated HTML and caching files
#   make rebuild   - Clean and render everything from scratch
#   make help      - Print this help message

.PHONY: all session1 session2 clean rebuild help

# Central presentation files
S1_QMD = presentations/session-1-lme4.qmd
S2_QMD = presentations/session-2-brms.qmd

S1_HTML = presentations/session-1-lme4.html
S2_HTML = presentations/session-2-brms.html

all: $(S1_HTML) $(S2_HTML)
	@echo "✓ All presentations successfully rendered!"

session1: $(S1_HTML)
	@echo "✓ Session 1 presentation successfully rendered!"

session2: $(S2_HTML)
	@echo "✓ Session 2 presentation successfully rendered!"

# Rules for rendering slides
$(S1_HTML): $(S1_QMD) presentations/custom.scss presentations/animation_styles.css _quarto.yml
	@echo "Rendering Session 1 slides..."
	quarto render $(S1_QMD)

$(S2_HTML): $(S2_QMD) presentations/custom.scss presentations/animation_styles.css _quarto.yml
	@echo "Rendering Session 2 slides..."
	quarto render $(S2_QMD)

clean:
	@echo "Cleaning Quarto cache and output files..."
	rm -rf $(S1_HTML) $(S2_HTML) presentations/session-1-lme4_files presentations/session-2-brms_files
	@echo "✓ Clean up complete!"

rebuild: clean all

help:
	@echo "Nebrija Data Analysis Workshop 2026 Presentations Build Manager"
	@echo "=============================================================="
	@echo "Available targets:"
	@echo "  make all       - Render both slide decks (S1 & S2)"
	@echo "  make session1  - Render Session 1 slides (lme4 models)"
	@echo "  make session2  - Render Session 2 slides (brms Bayesian models)"
	@echo "  make clean     - Clear Quarto build cache and delete HTML files"
	@echo "  make rebuild   - Re-render both slides after cleaning cache"
	@echo "  make help      - Show this help menu"
