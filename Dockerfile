ARG NORMAL_RPM=bzip2
ARG ENTITLED_RPM=snappy


FROM registry.access.redhat.com/ubi9/ubi:latest AS pristine


FROM pristine AS registered
WORKDIR /tmp
COPY activation-key org-id ./
RUN subscription-manager register --org="$(cat org-id)" --activationkey="$(cat activation-key)"


FROM registered AS unregistered
RUN subscription-manager unregister


FROM pristine AS normal-installed
ARG NORMAL_RPM
RUN dnf -y install "$NORMAL_RPM"


FROM normal-installed AS normal-uninstalled
ARG NORMAL_RPM
RUN dnf -y remove "$NORMAL_RPM"


FROM registered AS entitled-installed
ARG ENTITLED_RPM
RUN dnf -y install "$ENTITLED_RPM"


FROM entitled-installed AS entitled-uninstalled
ARG ENTITLED_RPM
RUN dnf -y remove "$ENTITLED_RPM"


FROM entitled-uninstalled AS entitled-uninstalled-unregistered
RUN subscription-manager unregister


FROM pristine AS differ
RUN dnf -y install diffutils less

COPY --from=pristine / /mnt/pristine
COPY --from=registered / /mnt/registered
COPY --from=unregistered / /mnt/unregistered
COPY --from=normal-installed / /mnt/normal-installed
COPY --from=normal-uninstalled / /mnt/normal-uninstalled
COPY --from=entitled-installed / /mnt/entitled-installed
COPY --from=entitled-uninstalled / /mnt/entitled-uninstalled
COPY --from=entitled-uninstalled-unregistered / /mnt/entitled-uninstalled-unregistered

WORKDIR /mnt
COPY differ.sh ./
RUN ./differ.sh
