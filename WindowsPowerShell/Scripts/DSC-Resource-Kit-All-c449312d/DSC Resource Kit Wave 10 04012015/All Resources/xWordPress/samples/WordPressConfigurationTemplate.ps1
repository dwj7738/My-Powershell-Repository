# Generate a WordPress configuration base on the supplied parameters
# and returns it as a string.
param
(
        [Parameter(Mandatory = $true)]
        [string] $WordPressDatabase,

        [Parameter(Mandatory = $true)]
        [string] $WordPressUserName,

        [Parameter(Mandatory = $true)]
        [string] $PlainPassword
)

# Evaluate the string and return it.
return @"
<?php
/**
 * Custom WordPress configurations on "wp-config.php" file.
 *
 * This file has the following configurations: MySQL settings, Table Prefix, Secret Keys, WordPress Language, ABSPATH and more.
 * For more information visit {@link http://codex.wordpress.org/Editing_wp-config.php Editing wp-config.php} Codex page.
 * Created using {@link http://generatewp.com/wp-config/ wp-config.php File Generator} on GenerateWP.com.
 *
 * @package WordPress
 * @generator GenerateWP.com
 */


/* MySQL settings */
define( 'DB_NAME',     '$WordPressDatabase' );
define( 'DB_USER',     '$WordPressUserName' );
define( 'DB_PASSWORD', '$plainPassword' );
define( 'DB_HOST',     'localhost' );
define( 'DB_CHARSET',  'utf8' );


/* MySQL database table prefix. */
`$table_prefix = 'wp_';


/* Authentication Unique Keys and Salts. */
define('AUTH_KEY',         'A+*GsxEq2nUwk6>r1nq-KZ>QEMAescGQ =ABPb8XZC5GBT6e{rNN{2q%m+*2Olm{');
define('SECURE_AUTH_KEY',  'Cu-`M;u{;EOvLG]#-%?!<.-W+JUd;]V-mp');
define('SECURE_AUTH_SALT', 'wxL+^S{ZbHt2EuH-X}:b=qxA9a< K?JUn2|Pd!C,gMS)[j?-cU/7RI|a<&LMy[;O');
define('LOGGED_IN_SALT',   'X%M60z[N7Ra?/{~C3hE%7WjMPnJU-u-Ds]1Of,`K=T&Qm (>/pjfy^Om]w _d<(-');
define('NONCE_SALT',       '31NY);q.~W[K},#1>z9}AU:(Jh?Tm-l1Zo))b@`{Ho,j)tuK)|=2a=(E,{zxz*;e');


/* WordPress Localized Language. */
define( 'WPLANG', '' );




/* Media Trash. */
define( 'MEDIA_TRASH', true );


/* Multisite. */
define( 'WP_ALLOW_MULTISITE', true );

/* Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');

/* Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');
"@
