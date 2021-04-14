# To run the container:
#    docker run -d -p 5000:5000 osrm-cil:1
#

FROM ubuntu:latest AS download-and-merge

LABEL maintainer "Antoine Barthelemy <a.barthelemy@cil-lamballe.com>"

RUN apt-get update -q \
 && DEBIAN_FRONTEND=noninteractive apt-get install -yq \
	wget \
	osmium-tool \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir /data

WORKDIR /data

RUN for i in bretagne pays-de-la-loire basse-normandie centre; do \
		wget http://download.geofabrik.de/europe/france/${i}-latest.osm.pbf ; \
	done

RUN osmium merge bretagne-latest.osm.pbf pays-de-la-loire-latest.osm.pbf basse-normandie-latest.osm.pbf centre-latest.osm.pbf -o /data/map.osm.pbf



FROM osrm/osrm-backend AS extract

WORKDIR /

COPY --from=0 /data /data

WORKDIR /data

RUN osrm-extract -p /opt/car.lua /data/map.osm.pbf

RUN rm /data/map.osm.pbf

RUN osrm-partition /data/map.osrm

RUN osrm-customize /data/map.osrm

EXPOSE 5000/tcp

ENTRYPOINT osrm-routed --algorithm mld /data/map.osrm
