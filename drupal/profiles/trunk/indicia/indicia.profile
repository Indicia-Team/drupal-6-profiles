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
 * Return a list of tasks that this profile supports.
 *
 * @return
 *   A keyed array of tasks the profile will perform during
 *   the final stage. The keys of the array will be used internally,
 *   while the values will be displayed to the user in the installer
 *   task list.
 */
function indicia_profile_task_list() {
}

/**
 * Perform any final installation tasks for this profile.
 */
function indicia_profile_tasks(&$task, $url) {

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

  // Don't display date and author information for page nodes by default.
  $theme_settings = variable_get('theme_settings', array());
  $theme_settings['toggle_node_info_page'] = FALSE;
  variable_set('theme_settings', $theme_settings);

  // Update the menu router information.
  menu_rebuild();
  
  // set the site home page
  variable_set('site_frontpage', 'instant-indicia-welcome');
  
  // remove the navigation menu, since admin_menu covers it
  db_query("UPDATE {blocks} SET region='', status=0 WHERE module='user' AND delta='1'");
}

/**
 * Implementation of hook_form_alter().
 *
 * Allows the profile to alter the site-configuration form. This is
 * called through custom invocation, so $form_state is not populated.
 * The site configuration form is also extended to allow the user to specify
 * the website ID and password for connecting to the warehouse.
 */
function indicia_form_alter(&$form, $form_state, $form_id) {
  if ($form_id == 'install_configure') {
    // Set default for site name field.
    $form['site_information']['site_name']['#default_value'] = $_SERVER['SERVER_NAME'];
    // Add Indicia website configuration controls.
    $form['indicia_config'] = array(
      '#type' => 'fieldset',
      '#title' => t('Indicia Configuration'),
      '#weight' => 5,
      '#collapsible' => TRUE,
      '#collapsed' => FALSE,
    );
    $form['indicia_config']['indicia_website_id'] = array(
      '#type' => 'textfield',
      '#title' => t('Indicia Website ID'),
      '#description' => 'Please enter the ID given to your website record when your website was registered on the Indicia Warehouse.',
      '#size' => 10,
      '#maxlength' => 10,
      '#required' => TRUE,
    );
    $form['indicia_config']['indicia_password'] = array(
      '#type' => 'textfield',
      '#title' => t('Indicia Website Password'),
      '#description' => 'Please enter the password specified when your website was registered on the Indicia Warehouse.',
      '#size' => 30,
      '#maxlength' => 30,
      '#required' => TRUE,
    );
  }
}
