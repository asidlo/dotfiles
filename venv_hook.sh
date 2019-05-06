# Creates a symlink for both the conda and activate commands to each new
# virtualenv created using pyenv using a conda base image, this will allow all
# functionality to work with pyenv virtualenv

# If using homebrew, place script here: /usr/local/var/homebrew/linked/pyenv/pyenv.d/virtualenv
# create the virtualenv dir if necessary

after_virtualenv "BASE_VERSION=\"$(echo $VIRTUALENV_NAME | awk -F/ '{print $(NF-2)}')\""
after_virtualenv "VENVNAME=\"$(echo $VIRTUALENV_NAME | awk -F/ '{print $(NF)}')\""
after_virtualenv 'CONDA=${PYENV_ROOT}/versions/${BASE_VERSION}/bin/conda'
after_virtualenv 'ACTIVATE=${PYENV_ROOT}/versions/${BASE_VERSION}/bin/activate'

after_virtualenv 'if [[ $BASE_VERSION = *"conda"* ]]; then echo "...linking conda and activate"; fi'
after_virtualenv 'if [[ $BASE_VERSION = *"conda"* ]]; then ln -s ${CONDA} ${PYENV_ROOT}/versions/${VENVNAME}/bin/; fi'
after_virtualenv 'if [[ $BASE_VERSION = *"conda"* ]]; then ln -s ${ACTIVATE} ${PYENV_ROOT}/versions/${VENVNAME}/bin/; fi'
