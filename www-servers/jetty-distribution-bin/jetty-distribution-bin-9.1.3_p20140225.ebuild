# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Mozna dodac:
#  - instalacje serwisu pod inna nazwa, np: jetty-distribution-bin -> /etc/init.d/jetty-distribution-bin (IUSE=shortsrvname)
# 
#

EAPI="5"

inherit eutils user versionator

DESCRIPTION="Jetty Web Server; Java Servlet container"
HOMEPAGE="https://www.eclipse.org/jetty/"
KEYWORDS="~amd64"
LICENSE="Apache-2.0;Eclipse-1.0"

IUSE="demo subslots srvdir extconf"

if use subslots ; then
	SLOT="$(get_major_version )/$(get_version_component_range 2 )$(get_version_component_range 3 )"
	MY_SLOT="$(get_major_version )-$(get_version_component_range 2 )$(get_version_component_range 3 )"
else
	SLOT="$(get_major_version )"
	MY_SLOT="${SLOT}"
fi

MY_PN="jetty-distribution"
MY_PV="${PV/_p/.v}"
MY_P="${MY_PN}-${MY_PV}"
MY_JETTY="${PN}-${MY_SLOT}"
JETTY_NAME="jetty"
JETTY_USER_NAME=${JETTY_NAME}
JETTY_SRV="${JETTY_NAME}-${MY_SLOT}"
JETTY_LOG_DIR="/var/log/${JETTY_SRV}"
JETTY_TMP_DIR="/var/lib/${JETTY_SRV}"
JETTY_CONF_DIR="/etc/${JETTY_NAME}"
JETTY_RUN_DIR="/run/${JETTY_NAME}"
JETTY_DEMO_BASE_NAME="demo-base"
if use srvdir ; then
	JETTY_INSTALL_DIR="/srv"
else
	JETTY_INSTALL_DIR="/opt"
fi

SRC_URI="http://archive.eclipse.org/jetty/${MY_PV}/dist/${MY_P}.tar.gz"


DEPEND=""
RDEPEND="${DEPEND}
	>=virtual/jre-1.7"

S="${WORKDIR}"

src_configure() {
	local jetty_home="${JETTY_INSTALL_DIR}/${P}"
	local jetty_run="${JETTY_RUN_DIR}"
	local jetty_user="${JETTY_USER_NAME}"
	local jetty_log_dir="${JETTY_LOG_DIR}"
	local jetty_tmp_dir="${JETTY_TMP_DIR}"
	local jetty_conf_dir="${JETTY_CONF_DIR}"
	local jetty_demo_base="${JETTY_INSTALL_DIR}/${JETTY_SRV}.${JETTY_DEMO_BASE_NAME}-${MY_PV}"

	local etc_confd="${S}/${MY_JETTY}.confd"
	local etc_demo_base_conf="${S}/${JETTY_DEMO_BASE_NAME}.conf"
	local etc_initd="${S}/${MY_JETTY}.initd"


	#
	# move demo-base
	#
	mv -vf ${S}/${MY_P}/demo-base "${S}"


	#
	# move jetty.sh
	#
	mv -vf ${S}/${MY_P}/bin/jetty.sh "${S}/${JETTY_SRV}.sh"
	

	#
	# conf.d
	#
	echo "## JETTY_HOME=${jetty_home}"                    > ${etc_confd} 
	echo "## JETTY_RUN=${jetty_run}"                     >> ${etc_confd}
	echo "## JETTY_USER=${jetty_user}"                   >> ${etc_confd}
	echo "## JETTY_LOGS=${jetty_log_dir}"                >> ${etc_confd}
	echo "## TMPDIR=${jetty_tmp_dir}"                    >> ${etc_confd}
	echo ""                                              >> ${etc_confd}
	echo "JETTY_BASE=${jetty_home}"                      >> ${etc_confd}

	
	#
	# demo-base .conf
	#
	if use demo ; then
		echo "# ${JETTY_DEMO_BASE_NAME} config file"  > ${etc_demo_base_conf}
		echo ""                                      >> ${etc_demo_base_conf}
		echo "JETTY_BASE=${jetty_demo_base}"         >> ${etc_demo_base_conf}
	fi


	#
	# init script
	#
        echo "#!/sbin/runscript"                                                                                > ${etc_initd}
        echo "# Copyright 1999-2014 Gentoo Foundation"                                                         >> ${etc_initd}
        echo "# Distributed under the terms of the GNU General Public License v2"                              >> ${etc_initd}
        echo ""                                                                                                >> ${etc_initd}
        echo ""                                                                                                >> ${etc_initd}
	if use extconf ; then
		echo "export JETTY_HOME=\"\${JETTY_HOME:-${jetty_home}}\""                                     >> ${etc_initd}
		echo "export JETTY_RUN=\"\${JETTY_RUN:-${jetty_run}}\""                                        >> ${etc_initd}
		echo "export JETTY_USER=\"\${JETTY_USER:-${jetty_user}}\""                                     >> ${etc_initd}
	else
		echo "export JETTY_HOME=\"${jetty_home}\""                                                     >> ${etc_initd}
		echo "export JETTY_RUN=\"${jetty_run}\""                                                       >> ${etc_initd}
		echo "export JETTY_USER=\"${jetty_user}\""                                                     >> ${etc_initd}
	fi
        echo ""                                                                                                >> ${etc_initd}
        echo "JETTY_BASE_NAME=\${SVCNAME#*.}"                                                                  >> ${etc_initd}
        echo "if [ -n \"\${JETTY_BASE_NAME}\" ] && [ \${SVCNAME} != \"${JETTY_SRV}\" ]; then"                  >> ${etc_initd}
        echo "    export JETTY_PID=\"\${JETTY_RUN}/${JETTY_SRV}.\${JETTY_BASE_NAME}.pid\""                     >> ${etc_initd}
        echo ""                                                                                                >> ${etc_initd}
        echo "    if [ -f ${JETTY_CONF_DIR}/\${JETTY_BASE_NAME}.conf ]; then"                                  >> ${etc_initd}
        echo "        source ${JETTY_CONF_DIR}/\${JETTY_BASE_NAME}.conf"                                       >> ${etc_initd}
        echo "    fi"                                                                                          >> ${etc_initd}
        echo ""                                                                                                >> ${etc_initd}
        echo "    export JETTY_BASE=\"\${JETTY_BASE:-${JETTY_INSTALL_DIR}/${JETTY_SRV}.\${JETTY_BASE_NAME}}\"" >> ${etc_initd}
        echo ""                                                                                                >> ${etc_initd}
        echo ""                                                                                                >> ${etc_initd}
        echo "    ## export JETTY_CONF=\"${JETTY_CONF_DIR}/\${JETTY_BASE_NAME}.conf\""                         >> ${etc_initd}
        echo "    # if [ -z "$JETTY_CONF" ]; then"                                                             >> ${etc_initd}
        echo "    #     if [ -f ${JETTY_CONF_DIR}/\${JETTY_BASE_NAME}.conf ]; then"                            >> ${etc_initd}
        echo "    #         export JETTY_CONF=\"${JETTY_CONF_DIR}/\${JETTY_BASE_NAME}.conf\""                  >> ${etc_initd}
        echo "    #     elif [ -f /etc/conf.d/${JETTY_SRV}.\${JETTY_BASE_NAME} ]"                              >> ${etc_initd}
        echo "    #         export JETTY_CONF=\"/etc/conf.d/${JETTY_SRV}.\${JETTY_BASE_NAME}\""                >> ${etc_initd}
        echo "    #     elif [ -f /etc/conf.d/${JETTY_SRV} ]"                                                  >> ${etc_initd}
        echo "    #         export JETTY_CONF=\"/etc/conf.d/${JETTY_SRV}\""                                    >> ${etc_initd}
        echo "    #     fi"                                                                                    >> ${etc_initd}
        echo "    # fi"                                                                                        >> ${etc_initd}
        echo ""                                                                                                >> ${etc_initd}
        echo "else"                                                                                            >> ${etc_initd}
        echo "    export JETTY_PID=\"\${JETTY_RUN}/${JETTY_SRV}.pid\""                                         >> ${etc_initd}
        echo "    export JETTY_BASE=\"\${JETTY_BASE:-\${JETTY_HOME}}\""                                        >> ${etc_initd}
        echo "    ## export JETTY_CONF=\"/etc/conf.d/${JETTY_SRV}\""                                           >> ${etc_initd}
        echo "fi"                                                                                              >> ${etc_initd}
        echo ""                                                                                                >> ${etc_initd}
        echo ""                                                                                                >> ${etc_initd}
	if use extconf ; then
		echo "export JETTY_LOGS=\"\${JETTY_LOGS:-${jetty_log_dir}}\""                                  >> ${etc_initd}
		echo "export TMPDIR=\"\${TMPDIR:-${jetty_tmp_dir}}\""                                          >> ${etc_initd}
	else
		echo "export JETTY_LOGS=\"${jetty_log_dir}\""                                                  >> ${etc_initd}
		echo "export TMPDIR=\"${jetty_tmp_dir}\""                                                      >> ${etc_initd}
	fi
        echo ""                                                                                                >> ${etc_initd}
        echo "depend() {"                                                                                      >> ${etc_initd}
        echo "    need net"                                                                                    >> ${etc_initd}
        echo "}"                                                                                               >> ${etc_initd}
        echo ""                                                                                                >> ${etc_initd}
        echo "# start|stop|run|restart|check|supervise"                                                        >> ${etc_initd}
        echo "#   exec \${JETTY_HOME}/bin/${JETTY_SRV}.sh"                                                     >> ${etc_initd}
        echo "start() {"                                                                                       >> ${etc_initd}
        echo ""                                                                                                >> ${etc_initd}
        echo "if [ ! -d ${jetty_run} ]; then"                                                                  >> ${etc_initd}
        echo "    mkdir ${jetty_run}"	                                                                       >> ${etc_initd}
        echo "    chown ${jetty_user} ${jetty_run}"                                                            >> ${etc_initd}
        echo "fi"                                                                                              >> ${etc_initd}
        echo ""                                                                                                >> ${etc_initd}
        echo "    exec \${JETTY_HOME}/bin/${JETTY_SRV}.sh start"                                               >> ${etc_initd}
        echo "}"                                                                                               >> ${etc_initd}
        echo ""                                                                                                >> ${etc_initd}
        echo "stop() {"                                                                                        >> ${etc_initd}
        echo "    exec \${JETTY_HOME}/bin/${JETTY_SRV}.sh stop"                                                >> ${etc_initd}
        echo "}"                                                                                               >> ${etc_initd}
        echo ""                                                                                                >> ${etc_initd}
        echo "restart() {"                                                                                     >> ${etc_initd}
        echo "    exec \${JETTY_HOME}/bin/${JETTY_SRV}.sh restart"                                             >> ${etc_initd}
        echo "}"                                                                                               >> ${etc_initd}
        echo ""                                                                                                >> ${etc_initd}
        echo "status() {"                                                                                      >> ${etc_initd}
        echo "    exec \${JETTY_HOME}/bin/${JETTY_SRV}.sh status"                                              >> ${etc_initd}
        echo "}"                                                                                               >> ${etc_initd}
        echo ""                                                                                                >> ${etc_initd}
        echo "run() {"                                                                                         >> ${etc_initd}
        echo "    exec \${JETTY_HOME}/bin/${JETTY_SRV}.sh run"                                                 >> ${etc_initd}
        echo "}"                                                                                               >> ${etc_initd}
        echo ""                                                                                                >> ${etc_initd}
        echo "supervise() {"                                                                                   >> ${etc_initd}
        echo "    exec \${JETTY_HOME}/bin/${JETTY_SRV}.sh supervise"                                           >> ${etc_initd}
        echo "}"                                                                                               >> ${etc_initd}
        echo ""                                                                                                >> ${etc_initd}
        echo ""                                                                                                >> ${etc_initd}
}


src_install() {
	local jetty_run_dir="${JETTY_RUN_DIR}"
	local jetty_tmp_dir="${JETTY_TMP_DIR}"
	local jetty_log_dir="${JETTY_LOG_DIR}"
	local jetty_conf_dir="${JETTY_CONF_DIR}"
	local jetty_home="${JETTY_INSTALL_DIR}/${P}"
	local jetty_user="${JETTY_USER_NAME}"
	local jetty_demo_base="${JETTY_INSTALL_DIR}/${JETTY_SRV}.${JETTY_DEMO_BASE_NAME}-${MY_PV}"

	local etc_confd="${MY_JETTY}.confd"
	local etc_demo_base_conf="${JETTY_DEMO_BASE_NAME}.conf"
	local etc_initd="${MY_JETTY}.initd"


	keepdir ${jetty_conf_dir}
	keepdir ${jetty_log_dir}	
	keepdir ${jetty_tmp_dir}	

	newconfd "${etc_confd}" "${JETTY_SRV}"
	newinitd "${etc_initd}" "${JETTY_SRV}"

	if use demo ; then
		insinto ${jetty_demo_base}
		doins -r ${JETTY_DEMO_BASE_NAME}/*

		dosym   "/etc/init.d/${JETTY_SRV}" /etc/init.d/${JETTY_SRV}.${JETTY_DEMO_BASE_NAME}

		insinto ${JETTY_CONF_DIR}
		doins   ${etc_demo_base_conf}
	fi

	insinto ${jetty_home}
	doins   -r ${MY_P}/*

	exeinto ${jetty_home}/bin
	doexe   ${JETTY_SRV}.sh
}

pkg_preinst () {
	local jetty_home="${JETTY_INSTALL_DIR}/${P}"
	local jetty_user="${JETTY_USER_NAME}"

	local jetty_tmp_dir="${JETTY_TMP_DIR}"
	local jetty_log_dir="${JETTY_LOG_DIR}"
	local jetty_conf_dir="${JETTY_CONF_DIR}"

	local jetty_demo_base="${JETTY_INSTALL_DIR}/${JETTY_SRV}.${JETTY_DEMO_BASE_NAME}-${MY_PV}"


	enewgroup ${jetty_user}
	enewuser  ${jetty_user} -1 /bin/false ${jetty_tmp_dir} "${jetty_user}"

	fowners   ${jetty_user}:${jetty_user} "${jetty_home}"
	fowners   ${jetty_user}:${jetty_user} "${jetty_tmp_dir}"
	fowners   ${jetty_user}:${jetty_user} "${jetty_log_dir}"
	fowners   ${jetty_user}:${jetty_user} "${jetty_conf_dir}"

	fperms    g+w "${jetty_tmp_dir}"
	fperms    g+w "${jetty_log_dir}"

	if use demo ; then
		fowners   ${jetty_user}:${jetty_user} "${jetty_demo_base}"
	fi
}

pkg_postinst() {
	local jetty_base_name="jetty-base"

        # elog "The ${JETTY_SRV} init script expects to find the configuration file"
        # elog "${JETTY_SRV}.conf in ${JETTY_CONF_DIR} along with any extra files it may need."
        # elog ""
        elog ""
        elog ""
        elog "To create more Base Jetty, simply create a new config file "
	elog " ${jetty_base_name}.conf in ${JETTY_CONF_DIR}/ or "
        elog " ${JETTY_SRV}.${jetty_base_name} in /etc/conf.g/ for it and"
        elog "then create a symlink to the ${JETTY_SRV} init script from a link called"
        elog "${JETTY_SRV}.${jetty_base_name} - like so"
        elog "   cd ${JETTY_CONF_DIR}"
        elog "   ${EDITOR##*/} ${jetty_base_name}.conf"
        elog "or"
        elog "   cd /etc/conf.d"
        elog "   ${EDITOR##*/} ${jetty_base_name}"
        elog ""
        elog "   cd /etc/init.d"
        elog "   ln -s ${JETTY_SRV} ${JETTY_SRV}.${jetty_base_name}"
        elog ""
        elog "Config file need path to your jetty base directory:"
        elog "  JETTY_BASE=${JETTY_BASE}"
        elog "If there will be no path, it will look for base directory in:"
        elog "  JETTY_BASE=${JETTY_INSTALL_DIR}/${JETTY_SRV}.${jetty_base_name}"
        elog ""
        elog "To check configuration run:"
        elog "  /etc/init.d/${JETTY_SRV} status"
        elog ""
        elog "You can then treat ${JETTY_SRV}.new-base-name as any other service, so you can"
        elog "stop one jetty and start another if you need to."
        elog ""
        elog ""
}

#
# Startup a Unix Service using jetty.sh
# from: https://www.eclipse.org/jetty/documentation/current/startup-unix-service.html
#
#
# Practical Setup of a Jetty Service
#
# mkdir -p /opt/jetty      ## -> jetty-home
# mkdir -p /opt/web/mybase ## -> jetty-base
# mkdir -p /opt/jetty/temp ## -> jetty-temp -> /var/lib/${MY_JETTY}
#
# useradd --user-group --shell /bin/false --home-dir /opt/jetty/temp jetty
#
# [/opt/jetty]# tar -zxf /home/user/Downloads/jetty-distribution-9.1.0.v20131115.tar.gz 
#
# chown --recursive jetty /opt/jetty
# chown --recursive jetty /opt/web/mybase
#
# cp   /opt/jetty/jetty-distribution-9.1.0.v20131115/bin/jetty.sh     /etc/init.d/jetty
# echo "JETTY_HOME=/opt/jetty/jetty-distribution-9.1.0.v20131115"   > /etc/default/jetty
# echo "JETTY_BASE=/opt/web/mybase"                                >> /etc/default/jetty
# echo "TMPDIR=/opt/jetty/temp"                                    >> /etc/default/jetty
#
