#!/usr/bin/python3
# -*- coding: utf-8 -*-

"""Handles the whole flow of updating AHN files and BAG, and generating the 3D BAG"""

from sys import argv, exit

import yaml
import logging, logging.config

from bag3d.config import args
from bag3d.config import db
from bag3d.config import footprints
from bag3d.update import bag

from pprint import pformat

with open('logging.conf', 'r') as f:
    log_conf = yaml.safe_load(f)
logging.config.dictConfig(log_conf)
logger = logging.getLogger('bag3dapp')


def main():
    
    logger.debug("Parsing arguments and configuration file")
    
    args_in = args.parse_console_args(argv[1:])
    
    try:
        cfg = args.parse_config(args_in)
    except:
        exit(1)
    
    logger.debug(pformat(cfg))
    
    try:
        conn = db.db(
            dbname=cfg["database"]["dbname"],
            host=str(cfg["database"]["host"]),
            port=str(cfg["database"]["port"]),
            user=cfg["database"]["user"],
            password=cfg["database"]["pw"])
    except:
        exit(1)
    
    if args_in['get_bag']:
        logger.info("Restoring BAG database")
        # At this point an empty database should exists, restore_BAG 
        # takes care of the rest
        bag.restore_BAG(cfg["database"], doexec=False)

    if args_in['update_ahn']:
        logger.info("Updating AHN files")

    if args_in['import_tile_idx']:
        logger.info("Importing tile indexes")
        bag.import_index(cfg['polygons']["file"], cfg["database"]["dbname"], 
                         cfg['polygons']["schema"], str(cfg["database"]["host"]), 
                         str(cfg["database"]["port"]), cfg["database"]["user"], 
                         doexec=False)
        # Update BAG tiles to include the lower/left boundary
        footprints.update_tile_index(conn,
                                     table_index=[cfg['polygons']["schema"], 
                                                  cfg['polygons']["table"]],
                                     fields_index=[cfg['polygons']["fields"]["primary_key"], 
                                                   cfg['polygons']["fields"]["geometry"], 
                                                   cfg['polygons']["fields"]["unit_name"]]
                                     )
        bag.import_index(cfg['elevation']["file"], cfg["database"]["dbname"], 
                         cfg['elevation']["schema"], str(cfg["database"]["host"]), 
                         str(cfg["database"]["port"]), cfg["database"]["user"], 
                         doexec=False)
    else:
        # in case the BAG index was imported by some other way
        cols = conn.get_fields(cfg['polygons']["schema"], 
                               cfg['polygons']["table"])
        if 'geom_border' not in cols:
            footprints.update_tile_index(conn,
                                         table_index=[cfg['polygons']["schema"], 
                                                      cfg['polygons']["table"]],
                                         fields_index=[cfg['polygons']["fields"]["primary_key"], 
                                                       cfg['polygons']["fields"]["geometry"], 
                                                       cfg['polygons']["fields"]["unit_name"]]
                                         )

    if args_in['update_bag']:
        logger.info("Updating the BAG database")


    if args_in['run_3dfier']:
        logger.info("Parsing batch3dfier configuration")

        logger.info("Configuring AHN2-3 border tiles")
        
        logger.info("Running batch3dfier")
        
        logger.info("Importing batch3dfier output into database")
        
        logger.info("Joining 3D tables")

    if args_in['export']:
        logger.info("Exporting 3D BAG")
    
    conn.close()

if __name__ == '__main__':
    main()
