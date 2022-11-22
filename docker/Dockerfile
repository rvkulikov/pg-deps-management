FROM postgres:13-alpine as build

RUN echo https://dl-2.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories \
 && apk --no-cache add git make cmake libc-dev flex bison gcc postgresql-dev

COPY ./extension /tmp/annotate_query

RUN cd /tmp/annotate_query \
 && make USE_PGXS=1 \
 && make USE_PGXS=1 install

RUN echo 1  \
 && ls -la /tmp/annotate_query \
 && cat /tmp/annotate_query/annotate_query--1.0.0.sql \
 && cat /tmp/annotate_query/annotate_query--1.0.0.sql.in

FROM postgres:13-alpine as result

COPY --from=build /usr/local/share/postgresql/extension/annotate_query*     /usr/local/share/postgresql/extension/
COPY --from=build /usr/local/lib/postgresql/annotate_query*                 /usr/local/lib/postgresql/
COPY --from=build /usr/local/lib/postgresql/bitcode/annotate_query/         /usr/local/lib/postgresql/bitcode/annotate_query/
COPY --from=build /usr/local/lib/postgresql/bitcode/annotate_query.index.bc /usr/local/lib/postgresql/bitcode/annotate_query.index.bc