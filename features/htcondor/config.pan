unique template features/htcondor/config;

include 'features/htcondor/params';

# FIXME: add required Globus dependencies messed up by HTCondor RPMs
include 'features/htcondor/globus-fix';

# Fixme: Due to ATLAS_SUPPORT, we must remove condor before installing condor.x86_64
'/software/packages/{condor}' = null;
'/software/packages' = {
  if (CONDOR_CONFIG['version'] >= '8.3') {
    pkg_repl('condor-all.x86_64');
  } else {
    pkg_repl('condor.x86_64');
    };
  SELF;
};


# Add YUM repository
include 'repository/config/htcondor';


# When the package is reinstalled - re-run the config. Cause some config files may be overwritten.
'/software/components/spma/dependencies/post' = push('filecopy');

include 'components/filecopy/config';

'/software/components/filecopy/services' = {
  # Put the cluster Key file
  SELF[escape(CONDOR_CONFIG['pwd_file']+'.encoded')] =
    nlist('config', CONDOR_CONFIG['pwd_hash'],
				  'restart', 'base64 -d '+ CONDOR_CONFIG['pwd_file'] +'.encoded >'+CONDOR_CONFIG['pwd_file'],
				  'perms', '0400',
	    		);
  # Put the config files
  foreach(i;file;CONDOR_CONFIG['cfgfiles']){

    dummy = create(file['contents']);

    SELF[escape(file['path'])] = nlist('config', dummy['text'],
				       'restart', file['restart'] ,
				       'backup',false,
	                               );
  };


  SELF[escape(CONDOR_CONFIG['cfgdir'] + '/condor_config.local')] = nlist('config', CONDOR_CONFIG['config.local'],
				     	                                 'restart', CONDOR_CONFIG['restart'] ,
				     	                                 'backup',false,
					                                 );

  if(CONDOR_CONFIG['strict']){
    script = create('features/htcondor/templ/quattor_cleaning_script');
    SELF[escape(CONDOR_CONFIG['cfgdir']+'/quattor_cleaning_script.sh')] = nlist('config', script['text'],
										'backup',false,
										'perms','0775',
										 );
  };

  if(CONDOR_CONFIG['intel_mic']){
    script = create('features/htcondor/templ/condor_mic_discovery');
    SELF[escape('/usr/libexec/condor/condor_mic_discovery')] = nlist(
      'config', script['text'],
      'backup',false,
      'perms','0775',
    );
  };



  SELF;
};

#Set the condor service to be running at boot
include 'components/chkconfig/config';

prefix '/software/components/chkconfig/service';

'condor/on' = "";
'condor/add' = true;
'condor/startstop' = true;

