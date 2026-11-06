# Land or Water — commandes. Tout passe par uv (https://docs.astral.sh/uv/).
# La clé OpenRouter est lue dans ton terminal (OPENROUTER_API_KEY), jamais dans un fichier du repo.
# `python -m land_or_water` exécute directement le dossier land_or_water/ du projet, sans passer par le lien que uv
# installe dans .venv (qu'iCloud peut rendre illisible).

UV := uv run --quiet
CLI := $(UV) python -m land_or_water
GPT_OSS_PROVIDERS := coreweave,parasail,deepinfra,dekallm,akashml,cerebras
.PHONY: setup check pilot probe-gpt-oss run score figure hf status pack demo test truth clean-demo

setup:            ## installe Python et les dépendances
	uv sync

check: setup      ## gratuit : clé, plafond, fournisseurs, précisions, prix
	$(CLI) check

pilot: setup      ## quelques dizaines de centimes : stratégie de chaque modèle, 200 points, puis répétition générale aux réglages du run
	-$(CLI) check
	-$(CLI) pilot
	-$(CLI) preflight
	$(CLI) pack
	@printf "\nRapports : results/pilot/report.md (pilote) et results/pilot/preflight.md (répétition générale).\n"

probe-gpt-oss: setup ## < 1 centime : cherche un fournisseur qui fait tourner gpt-oss sans réflexion
	-$(CLI) probe --model gpt-oss-120b --provider $(GPT_OSS_PROVIDERS) --strategy raw
	-$(CLI) probe --model gpt-oss-20b --provider $(GPT_OSS_PROVIDERS),darkbloom --strategy raw
	$(CLI) pack

run: setup        ## ≈ 17 $, ~1 h 15 : 16 200 points × 24 modèles, seulement si la répétition générale est au vert ; relancer reprend
	$(CLI) run
	$(CLI) score
	$(CLI) figure
	$(CLI) pack
	@printf "\nRésultats : results/tweet/leaderboard.md et results/tweet/figures/.\n"

score:            ## recalcule classement et cartes à partir des réponses enregistrées
	$(CLI) score

figure:           ## figures et chiffres de RESULTS.md (results/tweet/figures/), à partir du classement
	$(CLI) figure

hf:               ## dossier hf/ du dataset Hugging Face (après score et figure), puis : hf upload solalzana/land-or-water hf --repo-type=dataset
	$(CLI) hf

status:           ## avancement et coût du run en cours (dans un autre terminal)
	$(CLI) status

pack:             ## compresse les réponses brutes pour le repo
	$(CLI) pack

demo: setup       ## tout le pipeline contre une fausse API, gratuit, dans results/demo/
	$(CLI) demo

test: setup       ## tests automatiques (fausse API)
	uv run --quiet pytest -q

truth:            ## reconstruit data/grid.csv (déjà dans le repo, inutile en temps normal)
	uv run --quiet --extra truth python scripts/build_truth.py

clean-demo:
	rm -rf results/demo
