
Deface::Override.new(:virtual_path => "spree/admin/shared/_configuration_menu",
                     :name => "add_saml_providers_link_configuration_menu",
                     :insert_bottom => "[data-hook='admin_configurations_sidebar_menu']",
                     :text => %q{<%= configurations_sidebar_menu_item Spree.t("social_authentication_saml"), spree.admin_saml_configs_path %>},
                     :disabled => false)

