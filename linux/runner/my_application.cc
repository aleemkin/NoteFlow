#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"
#include <webkit2/webkit2.h>

static const char* get_mime_type(const char* path) {
  if (g_str_has_suffix(path, ".html") || g_str_has_suffix(path, ".htm"))
    return "text/html; charset=utf-8";
  if (g_str_has_suffix(path, ".js") || g_str_has_suffix(path, ".mjs"))
    return "application/javascript; charset=utf-8";
  if (g_str_has_suffix(path, ".css"))
    return "text/css; charset=utf-8";
  if (g_str_has_suffix(path, ".json"))
    return "application/json; charset=utf-8";
  if (g_str_has_suffix(path, ".svg"))
    return "image/svg+xml";
  if (g_str_has_suffix(path, ".png"))
    return "image/png";
  if (g_str_has_suffix(path, ".jpg") || g_str_has_suffix(path, ".jpeg"))
    return "image/jpeg";
  if (g_str_has_suffix(path, ".webp"))
    return "image/webp";
  if (g_str_has_suffix(path, ".ico"))
    return "image/x-icon";
  if (g_str_has_suffix(path, ".woff2"))
    return "font/woff2";
  if (g_str_has_suffix(path, ".woff"))
    return "font/woff";
  if (g_str_has_suffix(path, ".ttf"))
    return "font/ttf";
  if (g_str_has_suffix(path, ".otf"))
    return "font/otf";
  if (g_str_has_suffix(path, ".wasm"))
    return "application/wasm";
  return "application/octet-stream";
}

static gchar* find_excalidraw_assets_dir(FlDartProject* project) {
  if (project != nullptr) {
    const gchar* p_assets = fl_dart_project_get_assets_path(project);
    if (p_assets != nullptr) {
      g_autofree gchar* test_file = g_build_filename(p_assets, "assets", "excalidraw", "index.html", nullptr);
      if (g_file_test(test_file, G_FILE_TEST_EXISTS)) {
        return g_strdup(p_assets);
      }
    }
  }

  g_autofree gchar* exe_link = g_file_read_link("/proc/self/exe", nullptr);
  if (exe_link != nullptr) {
    g_autofree gchar* exe_dir = g_path_get_dirname(exe_link);
    g_autofree gchar* p_assets = g_build_filename(exe_dir, "data", "flutter_assets", nullptr);
    g_autofree gchar* test_file = g_build_filename(p_assets, "assets", "excalidraw", "index.html", nullptr);
    if (g_file_test(test_file, G_FILE_TEST_EXISTS)) {
      return g_steal_pointer(&p_assets);
    }
  }

  g_autofree gchar* cwd = g_get_current_dir();
  g_autofree gchar* debug_assets = g_build_filename(cwd, "build", "linux", "x64", "debug", "bundle", "data", "flutter_assets", nullptr);
  g_autofree gchar* test_debug = g_build_filename(debug_assets, "assets", "excalidraw", "index.html", nullptr);
  if (g_file_test(test_debug, G_FILE_TEST_EXISTS)) {
    return g_steal_pointer(&debug_assets);
  }

  g_autofree gchar* root_assets = g_build_filename(cwd, nullptr);
  return g_steal_pointer(&root_assets);
}

static void on_nview_scheme_request(WebKitURISchemeRequest* request, gpointer user_data) {
  const gchar* assets_dir = static_cast<const gchar*>(user_data);
  const gchar* req_path = webkit_uri_scheme_request_get_path(request);

  while (req_path != nullptr && *req_path == '/') {
    req_path++;
  }
  if (req_path == nullptr || *req_path == '\0') {
    req_path = "index.html";
  }

  // Strip query string if present in path
  g_autofree gchar* path_clean = nullptr;
  const gchar* qmark = strchr(req_path, '?');
  if (qmark != nullptr) {
    path_clean = g_strndup(req_path, qmark - req_path);
    req_path = path_clean;
  }

  g_autofree gchar* full_path = nullptr;
  if (g_str_has_prefix(req_path, "assets/excalidraw/")) {
    full_path = g_build_filename(assets_dir, req_path, nullptr);
  } else {
    full_path = g_build_filename(assets_dir, "assets", "excalidraw", req_path, nullptr);
  }

  if (!g_file_test(full_path, G_FILE_TEST_EXISTS)) {
    g_autofree gchar* direct_path = g_build_filename(assets_dir, req_path, nullptr);
    if (g_file_test(direct_path, G_FILE_TEST_EXISTS)) {
      full_path = g_steal_pointer(&direct_path);
    }
  }

  g_autoptr(GFile) file = g_file_new_for_path(full_path);
  g_autoptr(GError) error = nullptr;
  GFileInputStream* stream = g_file_read(file, nullptr, &error);

  if (stream != nullptr) {
    g_autoptr(GFileInfo) info = g_file_input_stream_query_info(
        stream, G_FILE_ATTRIBUTE_STANDARD_SIZE, nullptr, nullptr);
    goffset size = -1;
    if (info != nullptr) {
      size = g_file_info_get_size(info);
    }
    const gchar* mime_type = get_mime_type(full_path);
    webkit_uri_scheme_request_finish(request, G_INPUT_STREAM(stream), size, mime_type);
    g_object_unref(stream);
  } else {
    g_warning("[nview scheme] 404: %s (%s)", full_path, error ? error->message : "not found");
    webkit_uri_scheme_request_finish_error(request, error);
  }
}

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_header_bar_set_title(header_bar, "noteflow");
    gtk_header_bar_set_show_close_button(header_bar, FALSE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
    gtk_widget_set_visible(GTK_WIDGET(header_bar), FALSE);
  } else {
    gtk_window_set_title(window, "noteflow");
    gtk_window_set_decorated(window, FALSE);
  }

  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  static bool s_scheme_registered = false;
  if (!s_scheme_registered) {
    s_scheme_registered = true;
    gchar* assets_dir = find_excalidraw_assets_dir(project);
    WebKitWebContext* context = webkit_web_context_get_default();
    WebKitSecurityManager* security = webkit_web_context_get_security_manager(context);
    webkit_security_manager_register_uri_scheme_as_secure(security, "nview");
    webkit_security_manager_register_uri_scheme_as_cors_enabled(security, "nview");
    webkit_web_context_register_uri_scheme(
        context, "nview", on_nview_scheme_request, assets_dir, g_free);
  }

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
