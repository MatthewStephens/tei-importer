<?php
/*
Plugin Name: TEI Importer
Plugin URI: http://github.com/clioweb/tei-import
Author: Jeremy Boggs
Version: 0.1
*/

class Tei_Importer {

    function tei_importer() {
        add_action( 'init', array( $this, 'init' ) );
        add_action( 'admin_init', array( $this, 'admin_init' ) );
        add_action( 'plugins_loaded', array( $this, 'loaded' ) );
        add_action( 'tei_importer_init', array( $this, 'textdomain' ) );
        add_filter('upload_mimes', array( $this, 'upload_mimes' ) );
        add_action( 'add_meta_boxes', array( $this, 'add_meta_boxes' ) );
        add_action('save_post', array( $this, 'save_custom_meta_data' ) );
        add_action( 'update_post_meta', array( $this, 'transform_xml' ) );
        add_action('post_edit_form_tag', array( $this, 'post_edit_form_tag' ) );
    }

    function init() {
        do_action( 'tei_importer_init' );
    }

    function admin_init() {
        do_action( 'tei_importer_admin_init' );
    }

    function loaded() {
        do_action( 'tei_importer_loaded' );
    }

    /**
     * Handles localization files.
     *
     * Plugin core localization files are in the 'languages' directory. Users
     * can also add custom localization files in
     * 'wp-content/tei-importer-files/languages' if desired.
     *
     * @uses load_textdomain()
     * @uses get_locale()
     */
    function textdomain() {
        $locale = get_locale();
        $mofile_custom = WP_CONTENT_DIR . "/tei-importer-files/languages/tei-importer-$locale.mo";
        $mofile_packaged = WP_PLUGIN_DIR . "/tei-importer/languages/tei-importer-$locale.mo";
        if ( file_exists( $mofile_custom ) ) {
            load_textdomain( 'tei-importer', $mofile_custom );
            return;
        } else if ( file_exists( $mofile_packaged ) ) {
            load_textdomain( 'tei-importer', $mofile_packaged );
            return;
        }
    }

    /**
     * Allow XML uploads.
     */
    function upload_mimes($mimes) {
        $mimes = array_merge($mimes, array('xml' => 'application/xml'));
        return $mimes;
    }

    /**
     * Transform TEI in post meta to HTML in post_content.
     */
    function transform_xml() {
        global $post;

        // Need to read the contents of the uploaded file.
        if ($tei = get_post_meta( $post->ID, 'tei_importer_file_attachment', true )) {

            $tei_content = file_get_contents($tei['file']);
            $xslt = file_get_contents( plugin_dir_path( __FILE__ ) . 'preprocess.xsl' );
            $xslt = str_replace('[PLUGIN_DIR]', plugins_url( 'images', __FILE__), $xslt);

            $xml_doc = new DOMDocument();
            $xml_doc->loadXML( $tei_content );

            $xsl_doc = new DOMDocument();
            $xsl_doc->loadXML( $xslt );

            $proc = new XSLTProcessor();
            $proc->importStylesheet( $xsl_doc );
            $newXml = $proc->transformToXML( $xml_doc );

            $post_content = $newXml;
            //echo $post_content; exit;
            $my_post = array(
                'ID' => $post->ID,
                'post_content' => $post_content,
            );


            // unhook functions to prevent infinite loop
            remove_action( 'update_post_meta', array($this, 'transform_xml'));
            remove_action('save_post', array( $this, 'save_custom_meta_data' ));

            // update the post, which calls save_post again
            wp_update_post( $my_post, true );

            // re-hook functions
            add_action( 'update_post_meta', array($this, 'transform_xml'));
            add_action('save_post', array( $this, 'save_custom_meta_data' ));

        }

    }

    function add_meta_boxes() {
        add_meta_box(
            'tei_importer_file_upload',
            __('TEI File:', 'tei-importer'),
            array($this, 'tei_file_upload'),
            'page',
            'normal',
            'high'
        );
    }

    /**
     * HTML for TEI file upload field.
     * check if it has a file--list name of uploaded file, allow for delete
     * allow multiple? not for the time being
     * if file is uploaded, show name
     * currently only allows only one file--new upload unlinks but does not delete
     */
    function tei_file_upload() {
        global $post;
        $html .= '<p class="description">';
        $tei_file = get_post_meta($post->ID, 'tei_importer_file_attachment', true );
        if (!$tei_file){
          $html .= 'Upload your TEI file.';
          $html .= '</p>';
        } else {
          $html .= 'You have already uploaded a TEI file. Uploading a new file will'
                 . 'replace it. Current file: '
                 . '<a href="'.$tei_file['url'].'">'.basename($tei_file['url']).'</a>'
                 . '</p>';
        }
           $html .= '<input type="file" id="tei_importer_file_attachment" name="tei_importer_file_attachment" value="" size="25">';

        wp_nonce_field(plugin_basename(__FILE__), 'tei_importer_file_attachment_nonce');

        echo $html;
    }

    /**
     * Parse data from TEI file upload field and save file to uploads folder.
     */
    function save_custom_meta_data($id) {

        if(!wp_verify_nonce($_POST['tei_importer_file_attachment_nonce'], plugin_basename(__FILE__))) {
            return $id;
        }

        if(defined('DOING_AUTOSAVE') && DOING_AUTOSAVE) {
          return $id;
        }

        $tei_file = $_FILES['tei_importer_file_attachment'];
        if(!empty($tei_file['name'])) {
            $supported_types = array('application/xml');
            $arr_file_type = wp_check_filetype(basename($tei_file['name']));
            $uploaded_type = $arr_file_type['type'];

            if(in_array($uploaded_type, $supported_types)) {
                $upload = wp_upload_bits($_FILES['tei_importer_file_attachment']['name'], null, file_get_contents($_FILES['tei_importer_file_attachment']['tmp_name']));

                if(isset($upload['error']) && $upload['error'] != 0) {
                    wp_die('There was an error uploading your file. The error is: ' . $upload['error']);
                } else {
                    update_post_meta($id, 'tei_importer_file_attachment', $upload);
                }
            }
            else {
                wp_die("The file type that you've uploaded is not TEI/XML.");
            }
        }
    }

    function post_edit_form_tag() {
        echo ' enctype="multipart/form-data"';
    }

}

$tei_importer = new Tei_Importer();
