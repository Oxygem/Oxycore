# ************************************************************
# Sequel Pro SQL dump
# Version 4096
#
# http://www.sequelpro.com/
# http://code.google.com/p/sequel-pro/
#
# Host: localhost (MySQL 5.5.32-MariaDB)
# Database: oxypanel
# Generation Time: 2013-10-13 13:38:33 +0000
# ************************************************************


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


# Dump of table billing_invoice
# ------------------------------------------------------------

CREATE TABLE `billing_invoice` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `group_id` int(10) unsigned NOT NULL,
  `name` varchar(64) NOT NULL DEFAULT '',
  `order_id` int(10) unsigned NOT NULL,
  `status` enum('Paid','Unpaid','Cancelled') NOT NULL DEFAULT 'Unpaid',
  `time_created` int(10) unsigned NOT NULL,
  `time_due` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table billing_invoice_items
# ------------------------------------------------------------

CREATE TABLE `billing_invoice_items` (
  `invoice_id` int(10) unsigned NOT NULL,
  `description` varchar(64) NOT NULL DEFAULT '',
  `price` int(6) unsigned NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table billing_invoice_transactions
# ------------------------------------------------------------

CREATE TABLE `billing_invoice_transactions` (
  `invoice_id` int(10) unsigned NOT NULL,
  `transaction_id` varchar(255) NOT NULL DEFAULT '',
  `transaction_gateway` varchar(32) NOT NULL DEFAULT '',
  `amount` int(6) unsigned NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table billing_order
# ------------------------------------------------------------

CREATE TABLE `billing_order` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `group_id` int(10) unsigned NOT NULL,
  `service_id` int(10) unsigned NOT NULL DEFAULT '0',
  `price` int(6) unsigned NOT NULL,
  `time_invoice` int(10) unsigned NOT NULL COMMENT 'time afterwhich next invoice is generated',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table network_device
# ------------------------------------------------------------

CREATE TABLE `network_device` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `group_id` tinyint(3) unsigned NOT NULL,
  `name` varchar(64) NOT NULL DEFAULT '',
  `status` enum('Active','Suspended') NOT NULL DEFAULT 'Active',
  `config` varchar(64) NOT NULL DEFAULT '',
  `type` enum('Server','Network','Storage') NOT NULL DEFAULT 'Server',
  `device_group_id` int(10) unsigned NOT NULL,
  `host` varchar(64) NOT NULL DEFAULT '',
  `ssh_port` int(4) NOT NULL,
  `ssh_user` varchar(64) NOT NULL DEFAULT '',
  `snmp_port` varchar(4) NOT NULL DEFAULT '',
  `snmp_community` varchar(64) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  FULLTEXT KEY `name_ft` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table network_group
# ------------------------------------------------------------

CREATE TABLE `network_group` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `group_id` int(10) unsigned NOT NULL,
  `name` varchar(64) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table network_ipblock
# ------------------------------------------------------------

CREATE TABLE `network_ipblock` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `group_id` int(10) unsigned NOT NULL,
  `name` varchar(64) NOT NULL DEFAULT '',
  `type` enum('IPv4','IPv6') NOT NULL DEFAULT 'IPv4',
  `subnet` varchar(64) NOT NULL DEFAULT '',
  `device_id` int(10) unsigned NOT NULL,
  `device_group_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table network_ipblock_ip
# ------------------------------------------------------------

CREATE TABLE `network_ipblock_ip` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ipblock_id` int(10) unsigned NOT NULL,
  `address` varchar(255) NOT NULL DEFAULT '',
  `status` enum('Used','Unused','Reserved') NOT NULL DEFAULT 'Unused',
  `service_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `address` (`address`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table services_cloud
# ------------------------------------------------------------

CREATE TABLE `services_cloud` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `group_id` int(10) unsigned NOT NULL,
  `name` varchar(64) NOT NULL DEFAULT '',
  `config` varchar(64) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table services_cloud_devices
# ------------------------------------------------------------

CREATE TABLE `services_cloud_devices` (
  `cloud_id` int(10) unsigned NOT NULL,
  `device_id` int(10) unsigned NOT NULL,
  `role` varchar(64) NOT NULL DEFAULT '',
  UNIQUE KEY `device_id` (`device_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table services_cloud_settings
# ------------------------------------------------------------

CREATE TABLE `services_cloud_settings` (
  `cloud_id` int(10) unsigned NOT NULL,
  `setting` varchar(32) NOT NULL DEFAULT '',
  `value` varchar(32) NOT NULL DEFAULT '',
  UNIQUE KEY `cloud_id` (`cloud_id`,`setting`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table services_service
# ------------------------------------------------------------

CREATE TABLE `services_service` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `group_id` int(10) unsigned NOT NULL,
  `name` varchar(64) NOT NULL DEFAULT '',
  `cloud_id` int(10) unsigned NOT NULL,
  `device_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table services_service_data
# ------------------------------------------------------------

CREATE TABLE `services_service_data` (
  `service_id` int(10) unsigned NOT NULL,
  `key` varchar(32) NOT NULL DEFAULT '',
  `value` varchar(128) NOT NULL DEFAULT '',
  UNIQUE KEY `service_id` (`service_id`,`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table services_service_lists
# ------------------------------------------------------------

CREATE TABLE `services_service_lists` (
  `service_id` int(10) unsigned NOT NULL,
  `list` varchar(32) NOT NULL DEFAULT '',
  `value` varchar(128) NOT NULL DEFAULT '',
  UNIQUE KEY `service_id` (`service_id`,`list`,`value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table user
# ------------------------------------------------------------

CREATE TABLE `user` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `email` varchar(128) NOT NULL DEFAULT '' COMMENT 'used to identify',
  `password` varchar(255) NOT NULL DEFAULT '' COMMENT 'hashed pw',
  `salt` varchar(255) NOT NULL DEFAULT '' COMMENT 'salt for hash',
  `group` tinyint(3) unsigned NOT NULL DEFAULT '2' COMMENT '0=admin;1=user;1>=custom',
  `name` varchar(255) NOT NULL DEFAULT '' COMMENT 'name/display only',
  `login_time` int(10) unsigned NOT NULL DEFAULT '0',
  `register_time` int(10) unsigned NOT NULL DEFAULT '0',
  `password_reset_key` varchar(255) NOT NULL DEFAULT '' COMMENT 'pwreset temp key',
  `password_reset_time` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'expire time on pwreset',
  `key1` varchar(255) NOT NULL DEFAULT '',
  `key2` varchar(255) NOT NULL DEFAULT '',
  `key3` varchar(255) NOT NULL DEFAULT '',
  `real_name` varchar(255) NOT NULL DEFAULT '',
  `address` text NOT NULL,
  `country` varchar(3) NOT NULL DEFAULT '',
  `credit` int(10) unsigned NOT NULL DEFAULT '0',
  `two_factor` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `pubkey` text NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table user_groups
# ------------------------------------------------------------

CREATE TABLE `user_groups` (
  `id` tinyint(3) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table user_messages
# ------------------------------------------------------------

CREATE TABLE `user_messages` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table user_permissions
# ------------------------------------------------------------

CREATE TABLE `user_permissions` (
  `group` tinyint(3) unsigned NOT NULL,
  `permission` varchar(64) NOT NULL DEFAULT '',
  UNIQUE KEY `group_id` (`group`,`permission`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;




/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
