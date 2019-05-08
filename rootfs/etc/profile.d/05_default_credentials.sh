if [[ ! -e /localhost/.config/gcloud/application_default_credentials.json ]]; then   
    . /etc/profile.d/_colors.sh
    echo -e "$(red Application Default Credentials do not exist. Run [gcloud auth application-default login] to configure them)"
fi         
