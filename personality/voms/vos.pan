# Template to build the VO list for the VOMS server based on VOs configured

unique template personality/voms/vos;

variable VOS = {
  if ( is_defined(VOMS_VOS) && (length(VOMS_VOS) == 0) ) {
	  foreach (vo;params;VOMS_VOS) {
	    SELF[length(SELF)] = vo;
	  };
  };
  if ( is_defined(SELF) ) {
    SELF;
  } else {
    list();
  };
};

variable CONTENTS = {
  contents = "#!/bin/sh\n";
  if ( is_defined(VOMS_VOS) && (length(VOMS_VOS) != 0) ) {
    foreach (vo;params;VOMS_VOS) {
      contents = contents + "/usr/sbin/voms-configure install --dbtype mysql --vo "+vo;
      contents = contents + " --createdb --deploy-database --dbauser "+params['dbUser'];
      contents = contents + " --dbapwd '"+params['dbPassword']+"' --dbusername "+params['dbUser'];
      contents = contents + " --dbpassword '"+params['dbPassword']+"' --core-port "+params['port'];
      contents = contents + " --dbname "+params['dbName'];
      if ( exists(params['timeout']) ) {
        contents = contents + ' --timeout '+params['timeout'];
      };
      contents = contents + ' --csrf-log-only ';
      contents = contents + " --mail-from "+params['adminEmail']+" --smtp-host "+VOMS_ADMIN_SMTP_HOST+"\n";
      contents = contents + "/usr/sbin/voms-db-util add-admin --vo "+vo+" --cert /etc/grid-security/hostcert.pem\n";
    };
  };
  contents = contents + "service voms restart\n";
  contents = contents + "service voms-admin stop; service voms-admin start\n";
  return(contents);
};

include { 'components/filecopy/config' };

'/software/components/filecopy/services/{/var/run/quattor/create-voms.sh}'=
  nlist(
    'config', CONTENTS,
    'owner', 'root:root',
    'perms', '0755',
    'restart', if (VOMS_TOMCAT_RESTART_CONFIG) { '/var/run/quattor/create-voms.sh'; } else { null; }
);

#/usr/sbin/voms-admin-configure install --dbtype mysql \
#--vo test_vo_mysql --createdb --deploy-database \
#--dbauser root --dbapwd pwd \
#--dbusername voms_admin_20 --dbpassword pwd \
#--port 54322 --mail-from ciccio@cnaf.infn.it \
#–smtp-host iris.cnaf.infn.it
