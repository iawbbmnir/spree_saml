# Spree SAML README

## Introduction

This code is a fork of the Spree
Social (https://github.com/spree/spree_social/) plugin for
Spree (http://spreecommerce.com/), the original plugin allows users to enrol
in Spree using OAuth services such as Twitter or Facebook via the Ruby
OmniAuth framework. This fork replaces that login behaviour allowing users to
login from a SAML identity provider such as OpenAM (http://openam.forgerock.org/) instead.

This plugin was built as material for use in a 2Keys (http://www.2keys.ca/)
client demonstration of SAML based Single Sign-On and released to GitHub in
the hopes that others in the Spree community may find it helpful.

**DISCLAIMER:** This is not production grade code, it has not been thoroughly tested, reviewed or audited, it is not supported or warrantied by 2Keys in any way.

The sections that follow outline how to build and deploy a Spree environment
that uses this plugin, they assume you have a functional OpenAM server
installation to test against.

## Configuring Spree as an OpenAM Service Provider

### Requirements

  * OpenAM Server **10.1 Xpress**
  * Spree **2.0.3** (see "Bitnami Spree Virtual Machine" section immediately below)
  * Spree SAML plugin TODO: replace with github address later

#### Installing Spree from Ruby Gem's collection

**NOTE:** This requires Ruby 1.9.3+ installed on your system. If you don't have this, it's probably easier to run the Bitnami prebuilt images (see next section)

If you are not using a prebuilt Bitnami VM, Spree 2.0.x can be installed
using:

        # Perquisite Gems
        gem install rails -v 3.2.14 # Install Rails Server into the system Gems
        gem install spree || gem install spree_cmd # Install Spree or Spree CMD (spree w/o circular deps)

        # Install
        SPREE_INSTANCE=spree_demo_store # The name of the Rails + Spree instance.
        SPREE_HOME=$(pwd)/${SPREE_INSTANCE} # Full path to where the Spree instance will be installed.
        rails _3.2.14_ new ${SPREE_INSTANCE} # Create a Rails server instance
        spree install ${SPREE_INSTANCE} -A --version=2.0.3 # Add Spree 2.0.3 metadata into Gemfile
        
        cd ${SPREE_HOME}
        SED=$(type -p gsed sed | head -1) # Find GNU sed
        ${SED} -ie "s/gem 'jquery-rails'/gem 'jquery-rails', '2.2.1'/" Gemfile # Patch Gemfile for JQuery needed by Spree 2.0.3
        bundle install # Install all bundles
        rails g spree:install # Set Admin Email + Password and create instance

Test the install by running the following command and opening a web browser to
[http://localhost:3000/]:

        rails server # Run Rails Server at http://localhost:3000/, use rails server -p 80 to run below port 1024

Next step: [Configure Spree to use Spree
Social|#ConfigureSpreetoUseSpreeSocial]

#### Bitnami pre-built Spree Virtual Machine

**NOTE:** This requires Virtualbox or VMWare.

This can be used to get a quickly working installation of Spree as a base to
build on:

[http://bitnami.com/stack/spree/virtual-machine]

Site Admin login: user: user@example.com &nbsp_place_holder;
&nbsp_place_holder;pw: bitnami

OS login: bitnami

**NOTE:** see [next section|#TimeSynchronization]

### Time Synchronization

{warning}It is critically important that all SAML parties have synchronized
time, this can be particularly problematic for VMs who's time can drift over
time or if VM hosts suspend/wake.{warning}

To prevent _**time mismatch problems**_, it's highly recommend that all idP
and SP servers be synced to the same NTP servers. Below is one way to do that
via _cron_ and _ntpdate_:

        sudo apt-get -y install ntpdate # Install NTP time sync utility

sudo crontab -e # Edit root crontab{code} and enter the following cronjob to
insure the server's time is accurate:

        # m h dom mon dow command  
          1 *  *   *   *  /usr/sbin/ntpdate pool.ntp.org >/dev/null 2>&1 # Synchronize time once every hour

### Spree SAML Plugin

#### Clone the Spree SAML code to the server

        ### install git either port install git-core or apt-get install git
        mkdir ~/git
        cd ~/git
        git clone git://github.com/jumpkick/spree_saml
        cd spree_saml
        SPREE_SOCIAL_HOME="$(pwd)"

#### Configure Spree to Use Spree Social

        cd "${SPREE_HOME}" # Replace ${SPREE_HOME} with your Spree install directory i.e. /opt/bitnami/spree
        if [ -e "${SPREE_SOCIAL_HOME}" ]; then

          # Queue up spree SAML DB structure changes
          DB_MIGRATE_FILE="$(rails generate migration SamlConfigurations | gsed -r 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g' | grep rb | sed -e 's/create//' -e 's/^[ \t]*//')"
          cp "${SPREE_SOCIAL_HOME}/db/migrate/*_saml_configurations.rb" "${DB_MIGRATE_FILE}"
          DB_MIGRATE_FILE="$(rails generate migration CreateUserAuthentications | gsed -r 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g' | grep rb | sed -e 's/create//' -e 's/^[ \t]*//')"
          cp "${SPREE_SOCIAL_HOME}/db/migrate/*_create_user_authentications.rb" "${DB_MIGRATE_FILE}"
        
          # Update the Gem's and change the DB structure
          bundle update
          bundle exec rake db:migrate

          # Inject dependencies into Gemfile
          echo >> Gemfile
          echo >> Gemfile
          echo "gem 'spree_social', :path => '${SPREE_SOCIAL_HOME}'" >> Gemfile
          echo "gem 'omniauth-saml', :git => 'git://github.com/ruvr/omniauth-saml.git'" >> Gemfile

          # Activate the SAML plugin
          bundle update

          # Start the Rails server
          rvmsudo rails server -p 80 # Start the Rails server on port 80
        else
          echo "Check your SPREE_SOCIAL_HOME variable is set and that the directory
          SPREE_SOCIAL_HOME exists and then try again."
        fi

#### Configuration Steps For Creating New IDP within Spree SAML

{note}Make sure that server names are resolvable both to OpenAM and the SP
server either through /etc/hosts entries or DNS entries on each server.{note}

  * Login using a Spree Admin user
  * Go to '/admin' page and click Configuration tab
  * On the right menu, choose Saml Authentication
  * Create "New SAML Configuration". Complete following fields (many others are not being used atm):
    1. **_Assertion Consumer Service URL_**: [http://website.example.com/users/auth/saml/callback]  
**NOTE:** Make sure that server names are resolvable both to OpenAM and the SP server either through /etc/hosts entries or DNS entries 
    2. **_Assertion Consumer Service Binding_**: urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect
    3. **_Name Identifier Format_**: urn:oasis:names:tc:SAML:2.0:nameid-format:transient
    4. **_Issuer_**: website.example.com
    5. **_IDP SSO Target URL_**: http(s)://openamserver/openam*/SSORedirect/metaAlias/idp*
    6. **_Host_**: OpenAM (this is for display purposes only)
    7. SLO, IDP Metadata, Authentication Context, IDP Certificate Fingerprint fields are not used
    8. Set **_Active_** to "Yes"
    9. **_IDP Certificate_** (remember to add \n after every line of the cert to format into 1 long line):  

        -----BEGIN CERTIFICATE-----\nMIICQDCCAakCBEeNB0swDQYJKoZIhvcNAQEEBQAwZzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCkNh\nbGlmb3JuaWExFDASBgNVBAcTC1NhbnRhIENsYXJhMQwwCgYDVQQKEwNTdW4xEDAOBgNVBAsTB09w\nZW5TU08xDTALBgNVBAMTBHRlc3QwHhcNMDgwMTE1MTkxOTM5WhcNMTgwMTEyMTkxOTM5WjBnMQsw\nCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTEUMBIGA1UEBxMLU2FudGEgQ2xhcmExDDAK\nBgNVBAoTA1N1bjEQMA4GA1UECxMHT3BlblNTTzENMAsGA1UEAxMEdGVzdDCBnzANBgkqhkiG9w0B\nAQEFAAOBjQAwgYkCgYEArSQc/U75GB2AtKhbGS5piiLkmJzqEsp64rDxbMJ+xDrye0EN/q1U5Of+\nRkDsaN/igkAvV1cuXEgTL6RlafFPcUX7QxDhZBhsYF9pbwtMzi4A4su9hnxIhURebGEmxKW9qJNY\nJs0Vo5+IgjxuEWnjnnVgHTs1+mq5QYTA7E6ZyL8CAwEAATANBgkqhkiG9w0BAQQFAAOBgQB3Pw/U\nQzPKTPTYi9upbFXlrAKMwtFf2OW4yvGWWvlcwcNSZJmTJ8ARvVYOMEVNbsT4OFcfu2/PeYoAdiDA\ncGy/F2Zuj8XJJpuQRSE6PtQqBuDEHjjmOQJ0rV/r8mO1ZCtHRhpZ5zYRjhRC9eCbjx9VrFax0JDC\n/FfwWigmrW0Y0Q==\n-----END CERTIFICATE-----
 
 Your IDP certificate can be found in the X509 block of the IDP Metadata @
http(s)://openamserver/openam*/saml2/jsp/exportmetadata.jsp*

**NOTE:** Github markdown renders this line with extra breaks after BEGIN and before END CERTIFCATE lines.


* Save the configuration and logout.

### OpenAM setup using Spree SAML

**Make sure that server names are resolvable both to OpenAM and the SP server either through /etc/hosts entries or DNS entries on each server.**

  * Register Remote Service Provider using Metadata URL: [http://website.example.com/users/auth/saml/metadata]
  * Set Name ID Format: urn:oasis:names:tc:SAML:2.0:nameid-format:transient
  * Add the following attibute mappers:
    * telephone=telephoneNumber
    * address=postalAddress
    * last_name=sn
    * uid=uid
    * name=uid
    * first_name=givenName
    * mail=mail
  * Save the new SP

**NOTE:** see [Time Synchronization|#TimeSynchronization] to insure that the OpenAM server has accurate time, otherwise expired assertions may be rejected by SPs.

### Require SAML authentication for all logins

Configuration Steps for Toggling Gatekeeper:

* Open _$\{SPREE_SOCIAL_HOME\}/app/models/spree/authentication_disabler.rb_
* Changing _**return true**_ for _**def self.login_disabled**_ will force login through SAML only. Reverse this step to disable SAML logins.
* Save changes then restart rails server

### Spree SAML Development Enhancements

**This is work that is beyond the scope of our demo, but are things people
wishing to use this plugin should probably complete before using it in a
production deployment.**

  * Admin cannot login when Spree SAML is enabled -> add groups=isMemberOf to OpenAM SP's Assertion Mappings, add group for users and group for admins to spree SAML and then check the login user's group
  * Enable Single Logout in Spree SAML, so that session can be expired when user signs out of OpenAM
  * Fix translation when hitting the "X" next to SAML authentication type on User's Account screen (optionally remove this if it doesn't need to be there)
  * Have address from SAML assertion appear during checkout process as default address

