//
//  Generated file. Do not edit.
//

#include "generated_plugin_registrant.h"

#include <skmtdart/skmtdart_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) skmtdart_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "SkmtdartPlugin");
  skmtdart_plugin_register_with_registrar(skmtdart_registrar);
}
