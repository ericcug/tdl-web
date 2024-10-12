  tdl:
    image: runningfat/tdl-web
    container_name: tdl
    restart: unless-stopped  
    network_mode: host    
    volumes:
      - /mnt/Downloads/tdl:/downloads
      - /data/tdl/config:/root/.tdl
