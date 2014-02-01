# ************************************************************
# Sequel Pro SQL dump
# Version 4096
#
# http://www.sequelpro.com/
# http://code.google.com/p/sequel-pro/
#
# Host: localhost (MySQL 5.5.32-MariaDB)
# Database: oxypanel
# Generation Time: 2014-02-01 16:57:26 +0000
# ************************************************************


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


# Dump of table log
# ------------------------------------------------------------

CREATE TABLE `log` (
  `object_type` varchar(16) NOT NULL DEFAULT '',
  `object_id` int(10) unsigned NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `time` int(10) unsigned NOT NULL,
  `action` varchar(128) NOT NULL DEFAULT '',
  `data` text NOT NULL
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
  `ssh_sudo` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `stat_interval` smallint(5) unsigned NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table network_device_stats
# ------------------------------------------------------------

CREATE TABLE `network_device_stats` (
  `device_id` int(11) unsigned NOT NULL,
  `time` int(10) unsigned NOT NULL,
  `type` varchar(16) NOT NULL DEFAULT '' COMMENT 'stat type (cpu,memory,disk)',
  `key` varchar(16) NOT NULL DEFAULT '' COMMENT 'specific',
  `value` int(10) unsigned NOT NULL COMMENT '% used',
  `percentage` int(10) unsigned NOT NULL,
  KEY `device_stats-device_id` (`device_id`),
  CONSTRAINT `device_stats-device_id` FOREIGN KEY (`device_id`) REFERENCES `network_device` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table network_group
# ------------------------------------------------------------

CREATE TABLE `network_group` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `group_id` int(10) unsigned NOT NULL,
  `name` varchar(64) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table network_ipblock_ip
# ------------------------------------------------------------

CREATE TABLE `network_ipblock_ip` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ipblock_id` int(10) unsigned NOT NULL,
  `address` varchar(255) NOT NULL DEFAULT '',
  `status` enum('Used','Unused','Reserved') NOT NULL DEFAULT 'Unused',
  `service_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `address` (`address`),
  KEY `ipblock_ip-ipblock_id` (`ipblock_id`),
  CONSTRAINT `ipblock_ip-ipblock_id` FOREIGN KEY (`ipblock_id`) REFERENCES `network_ipblock` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



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
  UNIQUE KEY `device_id` (`device_id`),
  KEY `cloud_devices-cloud_id` (`cloud_id`),
  CONSTRAINT `cloud_devices-device_id` FOREIGN KEY (`device_id`) REFERENCES `network_device` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `cloud_devices-cloud_id` FOREIGN KEY (`cloud_id`) REFERENCES `services_cloud` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
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
  UNIQUE KEY `service_id` (`service_id`,`key`),
  CONSTRAINT `service_data-service_id` FOREIGN KEY (`service_id`) REFERENCES `services_service` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
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
  `phone` int(10) unsigned NOT NULL DEFAULT '0',
  `credit` int(10) unsigned NOT NULL DEFAULT '0',
  `two_factor` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `pubkey` text NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table user_groups
# ------------------------------------------------------------

CREATE TABLE `user_groups` (
  `id` tinyint(3) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table user_messages
# ------------------------------------------------------------

CREATE TABLE `user_messages` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table user_permissions
# ------------------------------------------------------------

CREATE TABLE `user_permissions` (
  `group` tinyint(3) unsigned NOT NULL,
  `permission` varchar(64) NOT NULL DEFAULT '',
  UNIQUE KEY `group_id` (`group`,`permission`),
  CONSTRAINT `permissions-user_groups_id` FOREIGN KEY (`group`) REFERENCES `user_groups` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;




/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
