import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";

// Link "Nhu cầu mua/thuê" trong sidebar — quay về /mapping từ mọi trang.
export default {
  name: "sitetor-mapping-sidebar",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    if (!siteSettings.sitetor_mapping_enabled) {
      return;
    }

    withPluginApi((api) => {
      api.addCommunitySectionLink((baseSectionLink) => {
        return class SitetorMappingSectionLink extends baseSectionLink {
          name = "sitetor-mapping";
          route = "mapping";
          text = i18n("sitetor_mapping.title");
          title = i18n("sitetor_mapping.title");
          defaultPrefixValue = "user-group";
        };
      });
    });
  },
};
