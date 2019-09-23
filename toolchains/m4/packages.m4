m4_divert(`-1')

m4_define(`local_package', COPY packages/$1 lib-helpers/packages/$1/
RUN $3 lib-helpers/packages/$1/build.sh $2)

m4_define(`helpers_package', COPY --from=helpers /lib-helpers/packages/$1 lib-helpers/packages/$1/
RUN $3 lib-helpers/packages/$1/build.sh $2)

m4_divert`'m4_dnl
