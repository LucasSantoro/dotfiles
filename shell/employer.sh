# shell/employer.sh — employer-specific config, kept separate so it's a one-file
# swap when changing jobs. Deployed to ~/.shellrc.employer; sourced by common.sh.
# Keep secrets (API tokens etc.) out of here — put those in ~/.shellrc.local,
# which isn't committed.

# Coral
export HEROKU_ORGANIZATION=coral-energy
export HEROKU_APP=coral-core
