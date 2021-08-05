# Copy to /etc/profile.d to set bash profile environment
export SPLUNK_HOME=/opt/splunkforwarder
export PATH=$PATH:$SPLUNK_HOME/bin
alias shome='cd $SPLUNK_HOME'