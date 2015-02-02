# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"

inherit eutils user versionator

DESCRIPTION="Jetty Web Server; Java Servlet container"
HOMEPAGE="https://www.eclipse.org/jetty/"
KEYWORDS="~amd64"
LICENSE="Apache-2.0;Eclipse-1.0"

IUSE="demo baseoutside subslots srvdir extconf archived debug" ## jettyshcp jettyshmv

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
JETTY_USER="${JETTY_USER:-${JETTY_NAME}}"
JETTY_GROUP="${JETTY_GROUP:-${JETTY_NAME}}"
JETTY_SERVICE_NAME="${JETTY_NAME}-${MY_SLOT}"
JETTY_LOG_DIR="/var/log/${JETTY_SERVICE_NAME}"
JETTY_TMP_DIR="/var/lib/${JETTY_SERVICE_NAME}"
JETTY_CONF_DIR="/etc/${JETTY_SERVICE_NAME}"
JETTY_RUN_DIR="/run/${JETTY_SERVICE_NAME}"
JETTY_DEMO_BASE_NAME="demo-base"

if use srvdir ; then
    JETTY_INSTALL_DIR="/srv"
else
    JETTY_INSTALL_DIR="/opt"
fi

JETTY_HOME="${JETTY_INSTALL_DIR}/${P}"

if use demo ; then
    if use baseoutside ; then
        JETTY_BASE="${JETTY_INSTALL_DIR}/${P}-${JETTY_DEMO_BASE_NAME}"
    else
        JETTY_BASE="${JETTY_HOME}/${JETTY_DEMO_BASE_NAME}"
    fi
else
    JETTY_BASE="" ## "${JETTY_HOME}"
fi




if use archived ; then
    SRC_URI="http://archive.eclipse.org/jetty/${MY_PV}/dist/${MY_P}.tar.gz"
else
    SRC_URI="http://download.eclipse.org/jetty/${MY_PV}/dist/${MY_P}.tar.gz"
fi


DEPEND=""
RDEPEND="${DEPEND}
    >=virtual/jre-1.7"

S="${WORKDIR}"

src_unpack() {
    unpack ${A}
    if [ -f ${FILESDIR}/${P}-jetty-sh.patch ] ; then
        cd "${S}/${MY_P}/bin"
        epatch "${FILESDIR}/${P}-jetty-sh.patch"
    fi
}


src_configure() {
    local etc_confd_path="${S}/${MY_JETTY}.confd"
    local etc_demo_base_conf_path="${S}/${JETTY_DEMO_BASE_NAME}.conf"
    local etc_initd_path="${S}/${MY_JETTY}.initd"


    if use baseoutside ; then
        ##
        ## move demo-base
        ##
        mv -vf ${S}/${MY_P}/demo-base "${S}"
    fi

    ##
    ## move jetty.sh
    ##
    mv -vf ${S}/${MY_P}/bin/jetty.sh "${S}/${JETTY_SERVICE_NAME}.sh"
    

    ##
    ## conf.d
    ##
    echo "## JETTY_HOME=${JETTY_HOME}"                                                                                        > ${etc_confd_path} 
    echo "## JETTY_RUN =${JETTY_RUN_DIR}"                                                                                    >> ${etc_confd_path}
    echo "## JETTY_USER=${JETTY_USER}"                                                                                       >> ${etc_confd_path}
    echo "## JETTY_LOGS=${JETTY_LOG_DIR}"                                                                                    >> ${etc_confd_path}
    echo "## TMPDIR    =${JETTY_TMP_DIR}"                                                                                    >> ${etc_confd_path}
    echo "## CONFIGS   ="                                                                                                    >> ${etc_confd_path}
    echo ""                                                                                                                  >> ${etc_confd_path}
    echo "JETTY_BASE=${JETTY_HOME}"                                                                                          >> ${etc_confd_path}

    
    ##
    ## demo-base .conf
    ##
    if use demo ; then
        echo "# ${JETTY_DEMO_BASE_NAME} config file"                                                                          > ${etc_demo_base_conf_path}
        echo ""                                                                                                              >> ${etc_demo_base_conf_path}
        echo "JETTY_BASE=${JETTY_BASE}"                                                                                      >> ${etc_demo_base_conf_path}
    fi


    ##
    ## init script
    ##
        echo "#!/sbin/runscript"                                                                                              > ${etc_initd_path}
        echo "# Copyright 1999-2014 Gentoo Foundation"                                                                       >> ${etc_initd_path}
        echo "# Distributed under the terms of the GNU General Public License v2"                                            >> ${etc_initd_path}
        echo ""                                                                                                              >> ${etc_initd_path}
        echo ""                                                                                                              >> ${etc_initd_path}
    if use extconf ; then
        echo "export JETTY_HOME=\"\${JETTY_HOME:-${JETTY_HOME}}\""                                                           >> ${etc_initd_path}
        echo "export JETTY_RUN=\"\${JETTY_RUN:-${JETTY_RUN_DIR}}\""                                                          >> ${etc_initd_path}
        echo "export JETTY_USER=\"\${JETTY_USER:-${JETTY_USER}}\""                                                           >> ${etc_initd_path}
        echo "export JETTY_GROUP=\"\${JETTY_GROUP:-${JETTY_GROUP}}\""                                                        >> ${etc_initd_path}
    else
        echo "export JETTY_HOME=\"${JETTY_HOME}\""                                                                           >> ${etc_initd_path}
        echo "export JETTY_RUN=\"${JETTY_RUN_DIR}\""                                                                         >> ${etc_initd_path}
        echo "export JETTY_USER=\"${JETTY_USER}\""                                                                           >> ${etc_initd_path}
        echo "export JETTY_GROUP=\"${JETTY_GROUP}\""                                                                         >> ${etc_initd_path}
    fi
        echo ""                                                                                                              >> ${etc_initd_path}
        echo "JETTY_BASE_NAME=\${SVCNAME#*.}"                                                                                >> ${etc_initd_path}
        echo "if [ -n \"\${JETTY_BASE_NAME}\" ] && [ \${SVCNAME} != \"${JETTY_SERVICE_NAME}\" ]; then"                       >> ${etc_initd_path}
        echo "    export JETTY_PID=\"\${JETTY_RUN}/${JETTY_SERVICE_NAME}.\${JETTY_BASE_NAME}.pid\""                          >> ${etc_initd_path}
    if use extconf ; then
            echo "    export JETTY_STATE=\"\${JETTY_STATE:-\${JETTY_RUN}/${JETTY_SERVICE_NAME}.\${JETTY_BASE_NAME}.state}\"" >> ${etc_initd_path}
    else
            echo "    export JETTY_STATE=\"\${JETTY_RUN}/${JETTY_SERVICE_NAME}.\${JETTY_BASE_NAME}.state\""                  >> ${etc_initd_path}
    fi
        echo ""                                                                                                              >> ${etc_initd_path}
        echo "    if [ -f ${JETTY_CONF_DIR}/\${JETTY_BASE_NAME}.conf ]; then"                                                >> ${etc_initd_path}
        echo "        source ${JETTY_CONF_DIR}/\${JETTY_BASE_NAME}.conf"                                                     >> ${etc_initd_path}
        echo "    fi"                                                                                                        >> ${etc_initd_path}
        echo ""                                                                                                              >> ${etc_initd_path}
        if use baseoutside ; then
                echo "    export JETTY_BASE=\"\${JETTY_BASE:-${JETTY_INSTALL_DIR}/${P}-\${JETTY_BASE_NAME}}\""               >> ${etc_initd_path}
        else
                echo "    export JETTY_BASE=\"\${JETTY_BASE:-${JETTY_INSTALL_DIR}/${P}/\${JETTY_BASE_NAME}}\""               >> ${etc_initd_path}
        fi
        echo ""                                                                                                              >> ${etc_initd_path}
        echo "    ## export JETTY_CONF=\"${JETTY_CONF_DIR}/\${JETTY_BASE_NAME}.conf\""                                       >> ${etc_initd_path}
        echo "    # if [ -z "$JETTY_CONF" ]; then"                                                                           >> ${etc_initd_path}
        echo "    #     if [ -f ${JETTY_CONF_DIR}/\${JETTY_BASE_NAME}.conf ]; then"                                          >> ${etc_initd_path}
        echo "    #         export JETTY_CONF=\"${JETTY_CONF_DIR}/\${JETTY_BASE_NAME}.conf\""                                >> ${etc_initd_path}
        echo "    #     elif [ -f /etc/conf.d/${JETTY_SERVICE_NAME}.\${JETTY_BASE_NAME} ]"                                   >> ${etc_initd_path}
        echo "    #         export JETTY_CONF=\"/etc/conf.d/${JETTY_SERVICE_NAME}.\${JETTY_BASE_NAME}\""                     >> ${etc_initd_path}
        echo "    #     elif [ -f /etc/conf.d/${JETTY_SERVICE_NAME} ]"                                                       >> ${etc_initd_path}
        echo "    #         export JETTY_CONF=\"/etc/conf.d/${JETTY_SERVICE_NAME}\""                                         >> ${etc_initd_path}
        echo "    #     fi"                                                                                                  >> ${etc_initd_path}
        echo "    # fi"                                                                                                      >> ${etc_initd_path}
        echo ""                                                                                                              >> ${etc_initd_path}
        echo "else"                                                                                                          >> ${etc_initd_path}
        echo "    export JETTY_PID=\"\${JETTY_RUN}/${JETTY_SERVICE_NAME}.pid\""                                              >> ${etc_initd_path}
    if use extconf ; then
            echo "    export JETTY_STATE=\"\${JETTY_STATE:-\${JETTY_RUN}/${JETTY_SERVICE_NAME}.state}\""                     >> ${etc_initd_path}
    else
            echo "    export JETTY_STATE=\"\${JETTY_RUN}/${JETTY_SERVICE_NAME}.state\""                                      >> ${etc_initd_path}
    fi
        echo "    export JETTY_BASE=\"\${JETTY_BASE:-\${JETTY_HOME}}\""                                                      >> ${etc_initd_path}
        echo "    ## export JETTY_CONF=\"/etc/conf.d/${JETTY_SERVICE_NAME}\""                                                >> ${etc_initd_path}
        echo "fi"                                                                                                            >> ${etc_initd_path}
        echo ""                                                                                                              >> ${etc_initd_path}
        echo ""                                                                                                              >> ${etc_initd_path}
    if use extconf ; then
        echo "export JETTY_LOGS=\"\${JETTY_LOGS:-${JETTY_LOG_DIR}}\""                                                        >> ${etc_initd_path}
        echo "export TMPDIR=\"\${TMPDIR:-${JETTY_TMP_DIR}}\""                                                                >> ${etc_initd_path}
    else
        echo "export JETTY_LOGS=\"${JETTY_LOG_DIR}\""                                                                        >> ${etc_initd_path}
        echo "export TMPDIR=\"${JETTY_TMP_DIR}\""                                                                            >> ${etc_initd_path}
    fi
        echo ""                                                                                                              >> ${etc_initd_path}
        if use debug ; then
            echo "print_debug_info() {"                                                                                      >> ${etc_initd_path}
            echo ""                                                                                                          >> ${etc_initd_path}
        echo "    echo "                                                                                                     >> ${etc_initd_path}
        echo "    echo Debug service start script:"                                                                          >> ${etc_initd_path}
        echo "    echo     JETTY_USER      = [\${JETTY_USER}]"                                                               >> ${etc_initd_path}
        echo "    echo     JETTY_GROUP     = [\${JETTY_GROUP}]"                                                              >> ${etc_initd_path}
        echo "    echo     JETTY_HOME      = [\${JETTY_HOME}]"                                                               >> ${etc_initd_path}
        echo "    echo     JETTY_BASE      = [\${JETTY_BASE}]"                                                               >> ${etc_initd_path}
        echo "    echo     JETTY_BASE_NAME = [\${JETTY_BASE_NAME}]"                                                          >> ${etc_initd_path}
        echo "    echo     JETTY_RUN       = [\${JETTY_RUN}]"                                                                >> ${etc_initd_path}
        echo "    echo     JETTY_LOGS      = [\${JETTY_LOGS}]"                                                               >> ${etc_initd_path}
        echo "    echo     TMPDIR          = [\${TMPDIR}]"                                                                   >> ${etc_initd_path}
        echo "    echo     JETTY_PID       = [\${JETTY_PID}]"                                                                >> ${etc_initd_path}
        echo "    echo     JETTY_STATE     = [\${JETTY_STATE}]"                                                              >> ${etc_initd_path}
        echo "    echo     JETTY_CONF      = [\${JETTY_CONF}]"                                                               >> ${etc_initd_path}
        echo "    echo     CONFIGS         = [\${CONFIGS}]"                                                                  >> ${etc_initd_path}
        echo "    echo "                                                                                                     >> ${etc_initd_path}
            echo ""                                                                                                          >> ${etc_initd_path}
            echo "}"                                                                                                         >> ${etc_initd_path}
        fi
        echo ""                                                                                                              >> ${etc_initd_path}
        echo "depend() {"                                                                                                    >> ${etc_initd_path}
        echo "    need net"                                                                                                  >> ${etc_initd_path}
        echo "}"                                                                                                             >> ${etc_initd_path}
        echo ""                                                                                                              >> ${etc_initd_path}
        echo "# start|stop|restart|status"                                                                                   >> ${etc_initd_path}
        echo "#   exec \${JETTY_HOME}/bin/${JETTY_SERVICE_NAME}.sh"                                                          >> ${etc_initd_path}
        echo "start() {"                                                                                                     >> ${etc_initd_path}
        echo ""                                                                                                              >> ${etc_initd_path}
    echo "    ebegin \"Starting...\""                                                                                        >> ${etc_initd_path}
        echo ""                                                                                                              >> ${etc_initd_path}
        echo "    if [ ! -d ${JETTY_RUN_DIR} ]; then"                                                                        >> ${etc_initd_path}
        echo "        mkdir -p ${JETTY_RUN_DIR}"                                                                             >> ${etc_initd_path}
        echo "        chown ${JETTY_USER}:${JETTY_GROUP} ${JETTY_RUN_DIR}"                                                   >> ${etc_initd_path}
        echo "    fi"                                                                                                        >> ${etc_initd_path}
        echo ""                                                                                                              >> ${etc_initd_path}
    if use debug ; then
            echo "    print_debug_info"                                                                                      >> ${etc_initd_path}
            echo "    exec \${JETTY_HOME}/bin/${JETTY_SERVICE_NAME}.sh -d start \${CONFIGS}"                                 >> ${etc_initd_path}
    else
            echo "    exec \${JETTY_HOME}/bin/${JETTY_SERVICE_NAME}.sh start \${CONFIGS}"                                    >> ${etc_initd_path}
    fi
        echo ""                                                                                                              >> ${etc_initd_path}
    echo "    eend $?"                                                                                                       >> ${etc_initd_path}
        echo ""                                                                                                              >> ${etc_initd_path}
        echo "}"                                                                                                             >> ${etc_initd_path}
        echo ""                                                                                                              >> ${etc_initd_path}
        echo "stop() {"                                                                                                      >> ${etc_initd_path}
    echo "    ebegin \"Stopping...\""                                                                                        >> ${etc_initd_path}
    if use debug ; then
            echo "    print_debug_info"                                                                                      >> ${etc_initd_path}
            echo "    exec \${JETTY_HOME}/bin/${JETTY_SERVICE_NAME}.sh -d stop \${CONFIGS}"                                  >> ${etc_initd_path}
    else
            echo "    exec \${JETTY_HOME}/bin/${JETTY_SERVICE_NAME}.sh stop \${CONFIGS}"                                     >> ${etc_initd_path}
    fi
    echo "    eend $?"                                                                                                       >> ${etc_initd_path}
        echo "}"                                                                                                             >> ${etc_initd_path}
        echo ""                                                                                                              >> ${etc_initd_path}
        echo "restart() {"                                                                                                   >> ${etc_initd_path}
    echo "    ebegin \"Restarting...\""                                                                                      >> ${etc_initd_path}
    if use debug ; then
            echo "    print_debug_info"                                                                                      >> ${etc_initd_path}
            echo "    exec \${JETTY_HOME}/bin/${JETTY_SERVICE_NAME}.sh -d restart \${CONFIGS}"                               >> ${etc_initd_path}
    else         
            echo "    exec \${JETTY_HOME}/bin/${JETTY_SERVICE_NAME}.sh restart \${CONFIGS}"                                  >> ${etc_initd_path}
    fi
    echo "    eend $?"                                                                                                       >> ${etc_initd_path}
        echo "}"                                                                                                             >> ${etc_initd_path}
        echo ""                                                                                                              >> ${etc_initd_path}
        echo "status() {"                                                                                                    >> ${etc_initd_path}
    echo "    ebegin \"Checking...\""                                                                                        >> ${etc_initd_path}
    if use debug ; then
            echo "    print_debug_info"                                                                                      >> ${etc_initd_path}
            echo "    exec \${JETTY_HOME}/bin/${JETTY_SERVICE_NAME}.sh -d status \${CONFIGS}"                                >> ${etc_initd_path}
    else
            echo "    exec \${JETTY_HOME}/bin/${JETTY_SERVICE_NAME}.sh status \${CONFIGS}"                                   >> ${etc_initd_path}
    fi
    echo "    eend $?"                                                                                                       >> ${etc_initd_path}
        echo "}"                                                                                                             >> ${etc_initd_path}
        echo ""                                                                                                              >> ${etc_initd_path}
        echo ""                                                                                                              >> ${etc_initd_path}
        echo ""                                                                                                              >> ${etc_initd_path}
}


src_install() {
    local etc_confd="${MY_JETTY}.confd"
    local etc_demo_base_conf="${JETTY_DEMO_BASE_NAME}.conf"
    local etc_initd="${MY_JETTY}.initd"

    keepdir ${JETTY_CONF_DIR}
    keepdir ${JETTY_LOG_DIR}
    keepdir ${JETTY_TMP_DIR}

    newconfd "${etc_confd}" "${JETTY_SERVICE_NAME}"
    newinitd "${etc_initd}" "${JETTY_SERVICE_NAME}"

    if use demo ; then
        if use baseoutside ; then
            insinto ${JETTY_BASE}
            doins -r ${JETTY_DEMO_BASE_NAME}/*
        fi

        dosym   "/etc/init.d/${JETTY_SERVICE_NAME}" /etc/init.d/${JETTY_SERVICE_NAME}.${JETTY_DEMO_BASE_NAME}

        insinto ${JETTY_CONF_DIR}
        doins   ${etc_demo_base_conf}
    fi

    insinto ${JETTY_HOME}
    doins   -r ${MY_P}/*

    exeinto ${JETTY_HOME}/bin
    doexe   ${JETTY_SERVICE_NAME}.sh
}

pkg_preinst () {
    enewgroup ${JETTY_GROUP}
    enewuser  ${JETTY_USER} -1 -1 ${JETTY_TMP_DIR} "${JETTY_GROUP}"

    fowners   ${JETTY_USER}:${JETTY_GROUP} "${JETTY_HOME}"
    fowners   ${JETTY_USER}:${JETTY_GROUP} "${JETTY_TMP_DIR}"
    fowners   ${JETTY_USER}:${JETTY_GROUP} "${JETTY_LOG_DIR}"
    fowners   ${JETTY_USER}:${JETTY_GROUP} "${JETTY_CONF_DIR}"

    fperms    g+w "${JETTY_TMP_DIR}"
    fperms    g+w "${JETTY_LOG_DIR}"

    if use demo ; then
        if use baseoutside ; then
            fowners   ${JETTY_USER}:${JETTY_GROUP} "${JETTY_BASE}"
        fi
    fi
}

pkg_postinst() {
    local jetty_base_name="jetty-base"

        # elog "The ${JETTY_SERVICE_NAME} init script expects to find the configuration file"
        # elog "${JETTY_SERVICE_NAME}.conf in ${JETTY_CONF_DIR} along with any extra files it may need."
        # elog ""
        elog ""
        elog ""
        elog "Jetty server installed in: ${JETTY_HOME}"
    if use demo ; then
            elog "Demo installed in: ${JETTY_BASE}"
            elog "Demo config file: ${JETTY_CONF_DIR}/${JETTY_DEMO_BASE_NAME}.conf"
    fi
        elog ""
        elog ""
        elog "To create more Base Jetty, simply create a new config file "
    elog " ${jetty_base_name}.conf in ${JETTY_CONF_DIR}/ or "
        elog " ${JETTY_SERVICE_NAME}.${jetty_base_name} in /etc/conf.g/ for it and"
        elog "then create a symlink to the ${JETTY_SERVICE_NAME} init script from a link called"
        elog "${JETTY_SERVICE_NAME}.${jetty_base_name} - like so"
        elog "   cd ${JETTY_CONF_DIR}"
        elog "   ${EDITOR##*/} ${jetty_base_name}.conf"
        elog "or"
        elog "   cd /etc/conf.d"
        elog "   ${EDITOR##*/} ${jetty_base_name}"
        elog ""
        elog "   cd /etc/init.d"
        elog "   ln -s ${JETTY_SERVICE_NAME} ${JETTY_SERVICE_NAME}.${jetty_base_name}"
        elog ""
        elog "Config file need path to your jetty base directory:"
        elog "  JETTY_BASE=${JETTY_BASE}"
        elog "If there will be no path, it will look for base directory in:"
        if use baseoutside ; then
                echo "  JETTY_BASE=\"\${JETTY_BASE:-${JETTY_INSTALL_DIR}/${P}-\${JETTY_BASE_NAME}}\""
        else
                echo "  JETTY_BASE=\"\${JETTY_BASE:-${JETTY_INSTALL_DIR}/${P}/\${JETTY_BASE_NAME}}\""
        fi
        elog ""
        elog "To check configuration run command:"
        elog "  rc-service jetty-9.${JETTY_SERVICE_NAME} status"
        elog "or"
        elog "  /etc/init.d/${JETTY_SERVICE_NAME} status"
        elog ""
        elog "To start server run command:"
        elog "  rc-service jetty-9.${JETTY_SERVICE_NAME} start"
        elog "or"
        elog "  /etc/init.d/${JETTY_SERVICE_NAME} start"
        elog ""
        elog "To add as service run command:"
        elog "  rc-update add jetty-9.${JETTY_SERVICE_NAME}"
        elog ""
        elog "You can then treat ${JETTY_SERVICE_NAME}.new-base-name as any other service, so you can"
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
