# Custom abbreviation to set namespace for current kubectl context
# Using --current instead of $(kubectl config current-context) to avoid
# static evaluation at shell startup

abbr -a -g kcn kubectl config set-context --current --namespace
