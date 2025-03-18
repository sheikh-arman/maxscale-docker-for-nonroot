FROM registry.access.redhat.com/ubi8/ubi-minimal:8.10-1154

ARG MXS_VERSION

COPY --chmod=500 mariadb_repo_setup /tmp/mariadb_repo_setup
RUN /tmp/mariadb_repo_setup --mariadb-maxscale-version=${MXS_VERSION} --skip-check-installed

# Install MaxScale
RUN microdnf -y install maxscale shadow-utils && microdnf clean all
COPY maxscale.cnf /etc/

# Copy licenses. Required for OpenShift container certification.
COPY LICENSE /licenses/

# Expose REST API port.
EXPOSE 8989


COPY entrypoint.sh /docker-entrypoint.sh
# Create maxscale user
RUN groupadd -g 997 maxscale && \
    useradd -r -u 997 -g 995 -G root maxscale && \
    mkdir -p /var/lib/maxscale /var/run/maxscale /var/log/maxscale /var/cache/maxscale && \
    chmod +x docker-entrypoint.sh && \
    chown -R 995:995 /var/lib/maxscale /var/run/maxscale /var/log/maxscale /var/cache/maxscale && \
    chmod -R 770 /var/lib/maxscale /var/run/maxscale /var/log/maxscale /var/cache/maxscale

# Run as non root. Required for OpenShift container certification.
USER 995:995
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["maxscale","--nodaemon", "--log=stdout"]

