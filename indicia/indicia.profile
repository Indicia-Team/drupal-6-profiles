<?php

/**
 * Return an array of the modules to be enabled when this profile is installed.
 *
 * @return
 *   An array of modules to enable.
 */
function indicia_profile_modules() {
  return array(
    // standard Drupal install modules
    'color', 'comment', 'help', 'menu', 'taxonomy', 'dblog',
    // some additional generally handy modules
    'admin_menu', 'path',
    // Modules required for an Indicia site
    'ckeditor', 'iform', 'jquery_ui', 'jquery_update', 'terms_of_use',
    // modules for feature support
    'features', 'uuid', 'uuid_features',
    // enable welcome to instant indicia page
    'indicia_welcome'
  );
}

/**
 * Return a description of the profile for the initial installation screen.
 *
 * @return
 *   An array with keys 'name' and 'description' describing this profile,
 *   and optional 'language' to override the language selection for
 *   language-specific profiles.
 */
function indicia_profile_details() {
  return array(
    'name' => 'Instant Indicia',
    'description' => 'Select this profile to enable Indicia functionality and selection of other features for building online recording websites.'
  );
}

/**
 * Perform any final installation tasks for this profile.
 */
function indicia_profile_drupal_tasks() {

  // Insert default user-defined node types into the database. For a complete
  // list of available node type attributes, refer to the node type API
  // documentation at: http://api.drupal.org/api/HEAD/function/hook_node_info.
  $types = array(
    array(
      'type' => 'page',
      'name' => st('Page'),
      'module' => 'node',
      'description' => st("A <em>page</em>, similar in form to a <em>story</em>, is a simple method for creating and displaying information that rarely changes, such as an \"About us\" section of a website. By default, a <em>page</em> entry does not allow visitor comments and is not featured on the site's initial home page."),
      'custom' => TRUE,
      'modified' => TRUE,
      'locked' => FALSE,
      'help' => '',
      'min_word_count' => '',
    ),
    array(
      'type' => 'story',
      'name' => st('Story'),
      'module' => 'node',
      'description' => st("A <em>story</em>, similar in form to a <em>page</em>, is ideal for creating and displaying content that informs or engages website visitors. Press releases, site announcements, and informal blog-like entries may all be created with a <em>story</em> entry. By default, a <em>story</em> entry is automatically featured on the site's initial home page, and provides the ability to post comments."),
      'custom' => TRUE,
      'modified' => TRUE,
      'locked' => FALSE,
      'help' => '',
      'min_word_count' => '',
    ),
  );

  foreach ($types as $type) {
    $type = (object) _node_type_set_defaults($type);
    node_type_save($type);
  }

  // Default page to not be promoted and have comments disabled.
  variable_set('node_options_page', array('status'));
  variable_set('comment_page', COMMENT_NODE_DISABLED);

  // update some theme settings
  $theme_settings = variable_get('theme_settings', array());
  // Don't display date and author information for page nodes by default.
  $theme_settings['toggle_node_info_page'] = FALSE;
  // turn on the site slogan
  $theme_settings['toggle_slogan'] = TRUE;
  // set the logo
  $theme_settings['default_logo'] = FALSE;
  $theme_settings['logo_path'] = 'sites/default/files/logo.png';
  variable_set('theme_settings', $theme_settings);

  // Update the menu router information.
  menu_rebuild();
  
  // set the site home page
  variable_set('site_frontpage', 'instant-indicia-welcome');
  
  // remove the navigation menu, since admin_menu covers it
  db_query("UPDATE {blocks} SET region='', status=0 WHERE module='user' AND delta='1'");
}

function indicia_profile_task_list() {
  return array('configure_indicia' => st('Configure Indicia'));
}

function indicia_profile_tasks(&$task, $url) {
  if ($task=='profile') {
    $task = 'configure_indicia';
    indicia_profile_drupal_tasks();
    drupal_set_title(st('Configure Indicia'));
    require_once(drupal_get_path('module', 'iform').'/iform.admin.inc');
    return drupal_get_form('iform_configuration_form', $url);
  } else {
    // The form was submitted, so now we advance to the next task.
    $task = 'profile-finished';
    // set the theme
    variable_set('theme_default', 'framework');
    // this forces newly added nodes to be immediately available
    drupal_flush_all_caches();
  }
}

/**
 * Implementation of hook_form_alter().
 * Updates the install configure form with a default site title.
 */
function indicia_form_alter(&$form, $form_state, $form_id) {
  if ($form_id == 'install_configure') {
    // Set default for site name field.
    $form['site_information']['site_name']['#default_value'] = t('My Instant Indicia Site');    
    $form['site_information']['site_slogan'] = array(
      '#type' => 'textfield',
      '#title' => t('Slogan'),
      '#description' => t("Your site's motto, tag line, or catchphrase (often displayed alongside the title of the site).")
    );
    // add a form submit callback to store the additional site slogan. Also add the default handler otherwise
    // Drupal seems to drop it - contrary to documentation
    $form['#submit'][] = 'install_configure_form_submit';
    $form['#submit'][] = 'indicia_profile_form_submit';
  }
}

function indicia_profile_form_submit($form, &$form_state) {
  variable_set('site_slogan', $form_state['values']['site_slogan']);
}
