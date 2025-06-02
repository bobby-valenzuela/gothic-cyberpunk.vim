#!/usr/bin/perl

use JSON;
use Apache::DBI;
use Data::Dumper;
use LWP::UserAgent;
use URI::Encode qw(uri_encode uri_decode);

require '/home/control-io/metabase-tools/lib/header1.pl';

my $debug = 0;

if ($ARGV[0] eq 'debug'){$debug = 1;}


sub connect_to_databases
{

	my $sqldriverpath = &find_odbc_driver();
    my $proddev_metadb = 'internaluse-metabase001-cache.probax.io';
    my $proddev_sscore = 'internaluse-metabase001-cache.probax.io';
	
	if ( !$dbbvaws ) {

		# $dbbvaws = DBI->connect("DBI:Sybase:server=aws-pbx-mssql-core;database=sscore", "beyonce", "YD3RLTLU2ZcdgP5S") or die "could not connect: " . DBI->errstr; # SS DB AWS
		$dbbvaws = DBI->connect("DBI:ODBC:driver={$sqldriverpath};server=$proddev_sscore,1433;database=sscore;Encrypt=no;Uid=beyonce;Pwd=YD3RLTLU2ZcdgP5S","","", { RaiseError => 1 }) or die "could not connect"; # SS DB AWS
		$dbbvaws->{'LongReadLen'} = 200000;
		$dbbvaws->{'odbc_force_bind_type'} = 1;

		$query = "USE sscore";
		$sth = $dbbvaws->prepare($query);
		$sth->execute;
		
		$query = "SET ANSI_NULLS OFF";
		$sth = $dbbvaws->prepare($query);
		$sth->execute;

	}

}
&connect_to_databases();

sub wasabi_get_api_keys_byo_from_mspaccountid
{
	my $byo_msp_accountid = $_[0];

	$query = "
	OPEN SYMMETRIC KEY PWHist
		DECRYPTION BY PASSWORD='$s_k_pwh'
		
			SELECT 
				CONVERT(VARCHAR(MAX),DECRYPTBYKEY(primaryApiKey)),
				CONVERT(VARCHAR(MAX),DECRYPTBYKEY(secondaryApiKey))
			FROM 
				WasabiApiKeysBYO WHERE accountid='$byo_msp_accountid' AND isEnabled='1'
	CLOSE SYMMETRIC KEY PWHist";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	(my $sub_primary_key, my $sub_secondary_key) = $sth->fetchrow();

	return ($sub_primary_key, $sub_secondary_key);

}
sub wasabi_get_api_keys
{

	my $query = "
		OPEN SYMMETRIC KEY PWHist
		DECRYPTION BY PASSWORD='$s_k_pwh'

			SELECT 
				CONVERT(VARCHAR(MAX),DECRYPTBYKEY(primaryKey)),
				CONVERT(VARCHAR(MAX),DECRYPTBYKEY(secondaryKey))
			FROM WasabiApiKeys
			WHERE isProd='1' AND isEnabled='1'

		CLOSE SYMMETRIC KEY PWHist
	";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	(my $sub_primary_key, my $sub_secondary_key) = $sth->fetchrow();

	return ($sub_primary_key, $sub_secondary_key);

}
sub m365_wasabi_get_accountdetails_from_msdid
{
	my $sub_msdid = $_[0];

	my $query = "SELECT userid FROM MemberStorageDetails WHERE id='$sub_msdid' AND isEnabled='1'";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	my $sub_userid = $sth->fetchrow();

	my $query = "OPEN SYMMETRIC KEY PWHist
		DECRYPTION BY PASSWORD='$s_k_pwh'
		
		SELECT TOP(1)
			accountEmail,
			accountNum,
			CONVERT(VARCHAR(MAX),DECRYPTBYKEY(accountPass)),
			CONVERT(VARCHAR(MAX),DECRYPTBYKEY(accessKey)),
			CONVERT(VARCHAR(MAX),DECRYPTBYKEY(secretKey))
		FROM WasabiAccountsM365 WHERE userid='$sub_userid' AND isEnabled='1' ORDER BY id DESC
		
		CLOSE SYMMETRIC KEY PWHist
	";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	(my $sub_accountemail, my $sub_accountnum, my $sub_accountpass, my $sub_accesskey, my $sub_secretkey) = $sth->fetchrow();

	return ($sub_accountemail, $sub_accountnum, $sub_accountpass, $sub_accesskey, $sub_secretkey, $sub_msdid);
}
sub wasabi_api_get_totalusage_and_update_from_msdid
{
	my $sub_msdid = $_[0];
	my $sub_is_m365 = $_[1];
	
	my $sub_accountname = my $sub_accountnum = my $sub_accountpass = my $sub_accesskey = my $sub_secretkey = '';

	if($sub_is_m365 == 1){

		($sub_accountname, $sub_accountnum, $sub_accountpass, $sub_accesskey, $sub_secretkey, $sub_msdid) = &m365_wasabi_get_accountdetails_from_msdid($sub_msdid);
	}
	else{

		($sub_accountname, $sub_accountnum, $sub_accountpass, $sub_accesskey, $sub_secretkey, $sub_msdid) = &wasabi_get_accountdetails_from_msdid($sub_msdid);
	
	}

    if ($debug == 1){ print "Account Num:$sub_accountnum\n"; }
    if ($debug == 1){ print "Account Email:$sub_accountname\n"; }
    if ($debug == 1){ print "Account Pass:$sub_accountpass\n"; }
	
	# Get details
	my $query = "SELECT serverid,userid FROM MemberStorageDetails WHERE id='$sub_msdid'";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	(my $sub_serverid, my $sub_userid) = $sth->fetchrow();

	$query = "SELECT ConnectToStorageDownload FROM ServerStorageDetails WHERE serverid='$sub_serverid'";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	(my $api_server_s3) = $sth->fetchrow(); # Example: s3.us.east1.probax.io

	$wasabi_region = $api_server_s3; 
	$wasabi_region =~ s/s3\.//;
	$wasabi_region =~ s/\.probax.*//;
	$wasabi_region =~ s/1/-1/;
	$wasabi_region =~ s/2/-2/;
	$wasabi_region =~ s/3/-3/;
	$wasabi_region =~ s/\./-/g;
	# Example: s3.us.east1.probax.io -> us-east-1

	my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0, SSL_verify_mode => 0x00 },);
	$ua->timeout(60);

	my $sub_url = "https://partner.wasabisys.com/v1/accounts/$sub_accountnum/utilizations?latest=true";
	my $sub_body = '';
	if ($debug == 1){ print "GET URL:$sub_url\n"; }

	$query = "SELECT accountid FROM Members WHERE userid='$sub_userid' AND isEnabled='1'";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	my ($sub_accountid) = $sth->fetchrow();

	my $sub_accountownerid = &get_account_owner_from_accountid($sub_accountid);

				# MSPACCOUNTID
	$query = "SELECT COUNT(*) FROM SPLicence 
		INNER JOIN SPLicencePrice ON(SPLicence.type = SPLicencePrice.type AND SPLicence.subtype = SPLicencePrice.subtype )
		WHERE AccountID='$sub_accountownerid' AND SPLicence.isEnabled=1 
		AND SPLicencePriceID IN(SELECT splicencepriceid FROM MSPBackupTypes WHERE (isBYO=1 OR isBYOW=1))
	";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	my $byo_lic_count = $sth->fetchrow();
	my $using_byo = $byo_lic_count > 0 ? 1 : 0;
	my $sub_accountownerid_touse = $using_byo == 1 ?  $sub_accountownerid : 0;

	my $primary_api_key = my $secondary_api_key = '';

	if($sub_accountownerid_touse > 0){
		($primary_api_key, $secondary_api_key) = &wasabi_get_api_keys_byo_from_mspaccountid($sub_accountownerid_touse);
	}
	else{
		($primary_api_key, $secondary_api_key) = &wasabi_get_api_keys();
	}

	if ($debug == 1){ print "GET KEY:$primary_api_key\n"; }

	my $request = HTTP::Request->new("GET","$sub_url",HTTP::Headers->new());
	$request->header('Accept' => 'application/json');
	$request->header('Authorization' => "$primary_api_key");
	$request->header('Content-Type' => 'application/json');
	
	my $response_value = '';
	my $total_bucket_usage_mb = 0;

	my $response = $ua->request($request);
	
	if ($response->is_success) {

		$response_value = $response->decoded_content;
		my $json_data = from_json($response_value);

		$utilization_num = $json_data->[0]{UtilizationNum};
        $account_num = $json_data->[0]{AcctNum};
        $account_plan_num = $json_data->[0]{AcctPlanNum};
        $start_time = $json_data->[0]{StartTime};
        $end_time = $json_data->[0]{EndTime};
        $create_time = $json_data->[0]{CreateTime};
        $num_billable_objects = $json_data->[0]{NumBillableObjects};
        $num_deleted_objects = $json_data->[0]{NumBillableDeletedObjects};
        $raw_storage_bytes = $json_data->[0]{RawStorageSizeBytes};
        $padded_storage_bytes = $json_data->[0]{PaddedStorageSizeBytes};
        $metadata_bytes = $json_data->[0]{MetadataStorageSizeBytes};
        $deleted_storage_bytes = $json_data->[0]{DeletedStorageSizeBytes};
        $orphaned_storage_bytes = $json_data->[0]{OrphanedStorageSizeBytes};
        $min_storage_charge_bytes = $json_data->[0]{MinStorageChargeBytes};
        $num_api_calls = $json_data->[0]{NumAPICalls};
        $upload_bytes = $json_data->[0]{UploadBytes};
        $download_bytes = $json_data->[0]{DownloadBytes};
        $storage_wrote_bytes = $json_data->[0]{StorageWroteBytes};
        $storage_Read_bytes = $json_data->[0]{StorageReadBytes};
        $num_get_calls = $json_data->[0]{NumGETCalls};
        $num_put_calls = $json_data->[0]{NumPUTCalls};
        $num_delete_calls = $json_data->[0]{NumDELETECalls};
        $num_list_calls = $json_data->[0]{NumLISTCalls};
        $num_head_calls = $json_data->[0]{NumHEADCalls};
        $delete_bytes = $json_data->[0]{DeleteBytes};

		$sub_recycle_bin_bytes = $deleted_storage_bytes;
		$sub_recycle_bin_bytes = int($sub_recycle_bin_bytes);
	    if ($debug == 1){ print "\n\tRecycleBinBytes:$sub_recycle_bin_bytes Bytes"; }

		$sub_recycle_bin_mb = $deleted_storage_bytes/1024/1024;
		$sub_recycle_bin_mb = int($sub_recycle_bin_mb);
	    if ($debug == 1){ print "\n\tRecycleBinBytesMB:$sub_recycle_bin_mb MB"; }

		$total_usage_mb = ($padded_storage_bytes + $deleted_storage_bytes )/1024/1024;
		$total_usage_mb = int($total_usage_mb);
	    if ($debug == 1){ print "\n\tTotalUsage:$total_usage_mb MB\n\n"; }

		my $updatedate = time;

		if($sub_is_m365 == 1){

			# UPDATE THE STORAGE TUB IN HIVE
			my $query = "UPDATE MemberStorageDetails SET totalusage='$total_usage_mb',recyclebinusage='$sub_recycle_bin_mb',recyclebin_bytes='$sub_recycle_bin_bytes' WHERE id='$sub_msdid' AND isEnabled='1' AND type='vo365'";
			if ($debug == 1){ print "Updating msdid: $query\n\n"; }
			$sth = $dbbvaws->prepare($query);
			$sth->execute;
			
			# UPDATE WasabiAccountsM365
			my $query = "UPDATE WasabiAccountsM365 SET paddedStorageBytes='$padded_storage_bytes',deletedBytes='$delete_bytes',storageUpdateDate='$updatedate' WHERE userid='$sub_userid' AND isEnabled='1' AND isByo='0' AND isEnabled='1'";
			if ($debug == 1){ print "Updating WasabiAccountsM365: $query\n\n"; }
			$sth = $dbbvaws->prepare($query);
			$sth->execute;

		}
		else{

			# UPDATE THE STORAGE TUB IN HIVE
			my $query = "UPDATE MemberStorageDetails SET totalusage='$total_usage_mb',recyclebinusage='$sub_recycle_bin_mb',recyclebin_bytes='$sub_recycle_bin_bytes' WHERE id='$sub_msdid' AND isEnabled='1' AND type='object' AND subtype='wasabi'";
			if ($debug == 1){ print "Updating msdid: $query\n\n"; }
			$sth = $dbbvaws->prepare($query);
			$sth->execute;
			

			# UPDATE WasabiAccounts
			my $query = "UPDATE WasabiAccounts SET paddedStorageBytes='$padded_storage_bytes',deletedBytes='$delete_bytes',storageUpdateDate='$updatedate' WHERE msdid='$sub_msdid' AND isEnabled='1' ";
			if ($debug == 1){ print "Updating WasabiAccounts: $query\n\n"; }
			$sth = $dbbvaws->prepare($query);
			$sth->execute;

		}
	}
	else{
	
		$response_value = $response->decoded_content;
		if ($debug == 1){ print "Failed to contact API - skippping\n\n"; }
	
	}

}
sub wasabi_get_byoapikeys_from_mspaccountid_v2
{
	my $sub_accountid = $_[0]; 					# MSP ACCOUNTID
	$query = "
	OPEN SYMMETRIC KEY PWHist
		DECRYPTION BY PASSWORD='$s_k_pwh'
		
			SELECT 
				CONVERT(VARCHAR(MAX),DECRYPTBYKEY(primaryApiKey)),
				CONVERT(VARCHAR(MAX),DECRYPTBYKEY(secondaryApiKey))
			FROM 
				WasabiApiKeysBYO WHERE accountid='$sub_accountid' AND isEnabled='1'

	CLOSE SYMMETRIC KEY PWHist";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	my ($sub_primary_apikey,$sub_secondary_apikey) = $sth->fetchrow();

	return $sub_primary_apikey,$sub_secondary_apikey;
}
sub wasabi_create_subaccount_from_email_pass_serverid_msdid_v2
{

	my $sub_email = $_[0];
	my $sub_pass = $_[1];
	my $sub_serverid = $_[2];
	my $sub_msdid = $_[3];
	my $sub_enable_obj_lock = $_[4];
	my $sub_byo_mspaccountid = $_[5];
	my $sub_updatedb = $_[6];

	use JSON;
	use LWP::UserAgent;
	use URI::Encode qw(uri_encode uri_decode);

	if ( $sub_email eq '' || $sub_pass eq '' || $sub_serverid eq '' || $sub_msdid eq '' ){ return ('failed','notenoughinfo',""); }
	
	# ESCAPE AMPERSANDS
	$sub_pass =~ s/\&/%26/g;

	my $api_server = my $api_server_s3 = my $wasabi_region = my $wasabi_region_friendly = my $wasabi_account_id = '';

	$query = "SELECT GeoLocation FROM ServerStorageDetails WHERE serverid='$sub_serverid'";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	(my $wasabi_region) = lc($sth->fetchrow());

	$api_server = "partner.wasabisys.com";
	# $api_server = "partner.$wasabi_region.wasabisys.com";
	if ( $wasabi_region eq '' ){ return ('failed','region',"$wasabi_region"); }

	my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0, SSL_verify_mode => 0x00 },);
	$ua->timeout(60);

	my $sub_url = 'https://'.$api_server.'/v1/accounts';
	my $sub_body = qq(
		{
			"AcctName": "$sub_email",
			"IsTrial": false,
			"Password": "$sub_pass",
			"EnableFTP": false
		}
	);
	
	my $primary_api_key = my $secondary_api_key = '';

	# IF WE'VE BEEN SENT AN MSP ACCOUNT ID - THIS MEANS WE'RE ONBOARDING WITH BYO  - USE RELEVANT KEYS
	if($sub_byo_mspaccountid > 0){
		($primary_api_key, $secondary_api_key) = wasabi_get_byoapikeys_from_mspaccountid_v2($sub_byo_mspaccountid);
		
		print "BYO_KEY_FOUND: $primary_api_key\n";
		
		if($primary_api_key eq '' && $secondary_api_key ne ''){
			$primary_api_key = $secondary_api_key;
			$sub_byo_mspaccountid = 0;
		}
	}
	else{
		($primary_api_key, $secondary_api_key) = &wasabi_get_api_keys();

	}

	my $request = HTTP::Request->new("PUT","$sub_url",HTTP::Headers->new(),$sub_body);
	$request->header('Accept' => 'application/json');
	$request->header('Authorization' => "$primary_api_key");
	$request->header('Content-Type' => 'application/json');
	# $request->header('Content-Type' => 'application/x-www-form-urlencoded');

	my $response = $ua->request($request);
	
	if ($response->is_success) {

		my $message = $response->decoded_content;
		my $json_obj = from_json($message);

		$account_name = $json_obj->{AcctName};
		$account_num = $json_obj->{AcctNum};

		my $access_key = $json_obj->{AccessKey};
		my $secret_key = $json_obj->{SecretKey};
		my $is_byo = $sub_byo_mspaccountid > 0 ? 1 : 0;

		if($sub_updatedb == 1){

			my $query = "OPEN SYMMETRIC KEY PWHist
				DECRYPTION BY PASSWORD='$s_k_pwh'
				
					UPDATE WasabiAccounts SET accountNum='$account_num',accountName='$account_name',accessKey=EncryptByKey(Key_GUID('PWHist'),'$access_key'),secretKey=EncryptByKey(Key_GUID('PWHist'),'$secret_key') WHERE msdid = '$sub_msdid' AND accountNum='0' AND isEnabled='1' 
				
				CLOSE SYMMETRIC KEY PWHist
			";
			$sth = $dbbvaws->prepare($query);
			$sth->execute;
		}
		else{

			my $query = "OPEN SYMMETRIC KEY PWHist
				DECRYPTION BY PASSWORD='$s_k_pwh'
				
					INSERT INTO WasabiAccounts (accountName,accountPass,accountNum,accessKey,secretKey,msdid,isEnabled,isObjectLocked,isBYO) 
					VALUES (
						'$account_name',
						EncryptByKey(Key_GUID('PWHist'),'$sub_pass'),
						'$account_num',
						EncryptByKey(Key_GUID('PWHist'),'$access_key'),
						EncryptByKey(Key_GUID('PWHist'),'$secret_key'),
						'$sub_msdid',
						'1','$sub_enable_obj_lock','$is_byo'
					)
				
				CLOSE SYMMETRIC KEY PWHist
			";
			$sth = $dbbvaws->prepare($query);
			$sth->execute;
		}


		# Verify record added - grab account id
		my $cols = "id,accountNum"; 
		my $table = "WasabiAccounts"; 
		my $where = ['accountNum=', $account_num,' AND isEnabled=', 1]; 
		my $endquery = " ";
		($wasabi_account_id, $wasabi_accountnum) = &db_select($dbbvaws,$table,$cols,$where,$endquery,'','row');

		# LOG THIS
		my $cols = "userid"; my $table = "MemberStorageDetails"; 
		my $where = ['id=', $sub_msdid,' AND isEnabled=', 1]; my $endquery = " ";
		my ($tub_userid) = &db_select($dbbvaws,$table,$cols,$where,$endquery,'','row');
		
		($z, $z, $subx_accountid) = &get_username_userkey_accountid_from_userid($tub_userid);
		&logger_from_userid_logdata("$tub_userid","created a Wasabi account for $account_name in the $wasabi_region region","","$subx_accountid");

	}
	else{
		my $message = $response->decoded_content;
        if($response->code == 429){return 'rate-limit-reached';}
		my $is_byo = $sub_byo_mspaccountid > 0 ? 1 : 0;

		# IF FAILING
		if($sub_updatedb == 1){

			my $query = "OPEN SYMMETRIC KEY PWHist
				DECRYPTION BY PASSWORD='$s_k_pwh'
				
					UPDATE WasabiAccounts SET accountNum='-1',failedToCreate='1',isEnabled='0' WHERE msdid = '$sub_msdid' AND accountNum='0' AND isEnabled='1' 
				
				CLOSE SYMMETRIC KEY PWHist
			";
			$sth = $dbbvaws->prepare($query);
			$sth->execute;
		}else{

			my $query = "OPEN SYMMETRIC KEY PWHist
				DECRYPTION BY PASSWORD='$s_k_pwh'
				
					INSERT INTO WasabiAccounts (accountName,accountPass,accountNum,accessKey,secretKey,msdid,isEnabled,isObjectLocked,isBYO,failedToCreate 
					VALUES (
						'$sub_email',
						EncryptByKey(Key_GUID('PWHist'),'$sub_pass'),
						'0',
						EncryptByKey(Key_GUID('PWHist'),'none'),
						EncryptByKey(Key_GUID('PWHist'),'none'),
						'$sub_msdid',
						'0','$sub_enable_obj_lock','$is_byo','1'
					)
				
				CLOSE SYMMETRIC KEY PWHist
			";
			$sth = $dbbvaws->prepare($query);
			$sth->execute;

		}

		# LOG THIS
		my $cols = "userid"; my $table = "MemberStorageDetails"; 
		my $where = ['id=', $sub_msdid,' AND isEnabled=', 1]; my $endquery = " ";
		my ($tub_userid) = &db_select($dbbvaws,$table,$cols,$where,$endquery,'','row');
		
		($z, $z, $subx_accountid) = &get_username_userkey_accountid_from_userid($tub_userid);
		&logger_from_userid_logdata("$tub_userid","failed to create a Wasabi account for $account_name in the $wasabi_region region","","$subx_accountid");


		return ('failed','api',"$message");
	
	}



	return ("success",$wasabi_account_id,$wasabi_account_id);

}
sub wasabi_api_remove_m365_wasabi_account_from_msdid
{
	my $sub_msdid = $_[0];
	my $sub_is_immutable = $_[1];
	my $sub_is_byo = $_[2];

	$query = "SELECT userid FROM MemberStorageDetails WHERE id='$sub_msdid' AND hasBeenRemoved='2' AND isEnabled='0'"; 
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	my ($sub_userid) = $sth->fetchrow();

	# GUARD CALUSE
	return if $sub_userid eq '' || $sub_msdid eq '';

	if($sub_is_byo == 1){

		# END USER ACCOUNT
		$query = "SELECT accountid FROM Members WHERE userid='$sub_userid' AND isEnabled='1'"; 
		$sth = $dbbvaws->prepare($query);
		$sth->execute;
		my ($sub_accountid) = $sth->fetchrow();

		# GET RESELLER (MSP)
		$query = "SELECT SignedUpByAccount,isReseller FROM Accounts WHERE AccountID='$sub_accountid' AND isEnabled='1'"; 
		$sth = $dbbvaws->prepare($query);
		$sth->execute;
		my ($signedupby_account, $is_reseller) = $sth->fetchrow();

		my $account_owner = $is_reseller == 1 ? $sub_accountid : $signedupby_account;

		$query = "
		OPEN SYMMETRIC KEY PWHist
			DECRYPTION BY PASSWORD='$s_k_pwh'
			
				SELECT 
					CONVERT(VARCHAR(MAX),DECRYPTBYKEY(primaryApiKey)),
					CONVERT(VARCHAR(MAX),DECRYPTBYKEY(secondaryApiKey))
				FROM 
					WasabiApiKeysBYO WHERE accountid='$account_owner' AND isEnabled='1'

		CLOSE SYMMETRIC KEY PWHist";
		$sth = $dbbvaws->prepare($query);
		$sth->execute;
		($sub_primary_apikey,$sub_secondary_apikey) = $sth->fetchrow();
	
	}
	else{
		# GET OUR APIKEYS
		my $query = "
			OPEN SYMMETRIC KEY PWHist
			DECRYPTION BY PASSWORD='$s_k_pwh'

				SELECT 
					CONVERT(VARCHAR(MAX),DECRYPTBYKEY(primaryKey)),
					CONVERT(VARCHAR(MAX),DECRYPTBYKEY(secondaryKey))
				FROM WasabiApiKeys
				WHERE isProd='1' AND isEnabled='1'

			CLOSE SYMMETRIC KEY PWHist
		";
		$sth = $dbbvaws->prepare($query);
		$sth->execute;
		($sub_primary_apikey, $sub_secondary_apikey) = $sth->fetchrow();

	}

	$sub_primary_apikey = $sub_secondary_apikey if $sub_primary_apikey eq '';

	# GET WASABI ACCOUNT NUMBER
	my $query = "SELECT id, accountNum FROM WasabiAccountsM365 WHERE userid='$sub_userid' AND isImmutable='$sub_is_immutable' AND isByo='$sub_is_byo' AND isEnabled='1'";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	my ($sub_wasabi_accounts_id, $sub_wacm_accountid) = $sth->fetchrow();

	# SET TO '3' TO SHOW PROGRESS
	$query = "UPDATE MemberStorageDetails SET hasBeenRemoved='3' WHERE id='$sub_msdid' AND hasBeenRemoved='2' AND isEnabled='0'"; 
	$sth = $dbbvaws->prepare($query);
	$sth->execute;

	use JSON;
	use Amazon::S3;
	use LWP::UserAgent;
	my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0, SSL_verify_mode => 0x00 },);
	$ua->timeout(60);

	my $sub_url = 'https://partner.wasabisys.com/v1/accounts/'.$sub_wacm_accountid;
	
	my $request = HTTP::Request->new("DELETE","$sub_url",HTTP::Headers->new(),"");
	$request->header('Accept' => 'application/json');
	$request->header('Authorization' => "$sub_primary_apikey");
	$request->header('Content-Type' => 'application/json');

	my $response = $ua->request($request);
	$sub_currenttime = time;
	if ($response->is_success) {

		my $query = "
		OPEN SYMMETRIC KEY PWHist
			DECRYPTION BY PASSWORD='$s_k_pwh'

				UPDATE 
					WasabiAccountsM365 
				SET 
					isEnabled='0',updatedate='$sub_currenttime'
				WHERE 
					id='$sub_wasabi_accounts_id' AND userid='$sub_userid' AND isByo='$sub_is_byo' AND isImmutable='$sub_is_immutable' AND isEnabled='1' AND accountNum='$sub_wacm_accountid'
		
		CLOSE SYMMETRIC KEY PWHist
		";
		$sth = $dbbvaws->prepare($query);
		$sth->execute;

		$query = "UPDATE MemberStorageDetails SET hasBeenRemoved='4' WHERE id='$sub_msdid' AND hasBeenRemoved='3' AND isEnabled='0'"; 
		$sth = $dbbvaws->prepare($query);
		$sth->execute;

		
	}
	else{
		# COULD NOT REMOVE AN ACCOUNT WITH API KEYS PROVIDED
		my $message = $response->decoded_content;
		$query = "UPDATE MemberStorageDetails SET hasBeenRemoved='99' WHERE id='$sub_msdid' AND hasBeenRemoved='3' AND isEnabled='0'"; 
		$sth = $dbbvaws->prepare($query);
		$sth->execute;	

	}

}
sub qbee_wasabi_api_delete_wasabi_acct_from_msdid
{
	my $sub_msdid = $_[0];
	my $sub_byo_mspaccountid = $_[1];
	
	(my $sub_accountname, my $sub_accountnum, my $sub_accountpass, my $sub_accesskey, my $sub_secretkey, my $sub_msdid, my $obj_lock) = &wasabi_get_accountdetails_from_msdid($sub_msdid);

	use JSON;
	use LWP::UserAgent;
	use URI::Encode qw(uri_encode uri_decode);

	my $this_epoch = time;
	
	# Get details
	my $query = "SELECT serverid,userid FROM MemberStorageDetails WHERE id='$sub_msdid'";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	my ($sub_serverid, $sub_userid) = $sth->fetchrow();

	$query = "SELECT ConnectToStorageDownload FROM ServerStorageDetails WHERE serverid='$sub_serverid'";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	(my $api_server_s3) = $sth->fetchrow(); # Example: s3.us.east1.probax.io

	$wasabi_region = $api_server_s3; 
	$wasabi_region =~ s/s3\.//;
	$wasabi_region =~ s/\.probax.*//;
	$wasabi_region =~ s/1/-1/;
	$wasabi_region =~ s/2/-2/;
	$wasabi_region =~ s/3/-3/;
	$wasabi_region =~ s/\./-/g;
	# Example: s3.us.east1.probax.io -> us-east-1

	my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0, SSL_verify_mode => 0x00 },);
	$ua->timeout(60);

	my $sub_url = "https://partner.wasabisys.com/v1/accounts/$sub_accountnum";
	my $sub_body = '';

    my $primary_api_key = my $secondary_api_key = "";

	# IF WE'VE BEEN SENT AN MSP ACCOUNT ID - THIS MEANS WE'RE ONBOARDING WITH BYO  - USE RELEVANT KEYS
	if($sub_byo_mspaccountid > 0){
		($primary_api_key, $secondary_api_key) = wasabi_get_byoapikeys_from_mspaccountid_v2($sub_byo_mspaccountid);

        if($primary_api_key eq '' && $secondary_api_key  ne ''){ $primary_api_key = $secondary_api_key; }
		print "BYO_KEY_FOUND: $primary_api_key\n";
		
	}


	if($primary_api_key ne '' || $secondary_api_key ne ''){

	# (my $primary_api_key, my $secondary_api_key) = &wasabi_get_api_keys();

		my $request = HTTP::Request->new("DELETE","$sub_url",HTTP::Headers->new());
		$request->header('Accept' => 'application/json');
		$request->header('Authorization' => "$primary_api_key");
		$request->header('Content-Type' => 'application/json');
		
		my $response = $ua->request($request);

		my $deletion_succeeded = 0;
		
		if ($response->is_success) {

			$response_value = $response->decoded_content;
		print "SUCCESS: $response_value\n";
			my $deletion_status = from_json($response_value)->{Msg}; # Should return 'OK'

			$deletion_succeeded = 1;  
			# DISABLE AND SCHEDULE FOR DELETION
			$query = "UPDATE WasabiAccounts SET isEnabled='0',deletedDate='$this_epoch' WHERE msdid='$sub_msdid' AND accountNum='$sub_accountnum'";
			$sth = $dbbvaws->prepare($query);
			$sth->execute;
		}
		else{
			$response_value = $response->decoded_content;
			if($response->code == 429){ return 'rate-limit-reached';}
            my $deletion_status = from_json($response_value)->{Msg}; # Should return 'OK'
            print "FAILED: $response_value\n";

            if($deletion_status eq 'Account already deleted' || $deletion_status eq 'Entity Not Found'){
                $query = "UPDATE WasabiAccounts SET isEnabled='0',deletedDate='$this_epoch' WHERE msdid='$sub_msdid' AND accountNum='$sub_accountnum'";
                $sth = $dbbvaws->prepare($query);
                $sth->execute;
            }
            elsif($deletion_status eq 'You are not permitted to complete that action'){

                # FAILED TO DELETE - SET ATTEMPTED DELETED DATE, BUT DON'T DISABLE YET 
                $query = "UPDATE WasabiAccounts SET deletedDate='$this_epoch' WHERE msdid='$sub_msdid' AND accountNum='$sub_accountnum'";
                $sth = $dbbvaws->prepare($query);
                $sth->execute;

            }
		
		
			# Internal log
			&logger_from_userid_logdata("$sub_userid","failed to delete WAC subaccount | Serverid: $sub_serverid | Msdid: $sub_msdid | API Response: $response_value","","$sub_accountid",1);
		}

		return $deletion_succeeded;
	}
	else{
			&logger_from_userid_logdata("$sub_userid","failed to delete WAC subaccount | Serverid: $sub_serverid | Msdid: $sub_msdid | Msg: No JWT keys to use",1);

    return $deletion_succeeded;
    }

}
sub update_M365_wasabi_usages
{
	# UPDATE M365 WASABI TUB USAGES
	my $query = "SELECT 
					MemberStorageDetails.id,MemberStorageDetails.userid FROM MemberStorageDetails 
				INNER JOIN 
					WasabiAccountsM365 ON(MemberStorageDetails.userid = WasabiAccountsM365.userid)
				WHERE 
					type='vo365' AND subtype='wasabi' AND MemberStorageDetails.isEnabled='1' AND WasabiAccountsM365.isEnabled='1' AND isImmutable='0' AND isByo='0'";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	my $wasabi_tubs_m365 = $sth->fetchall_arrayref();

	print "\n[+] Processing M365 Wasabi Buckets \n\n";

	for my $u (0..$#{$wasabi_tubs_m365}){

		my $sub_userid = $wasabi_tubs_m365->[$u][1];
		if ($ARGV[1] ne '' && $sub_userid != $ARGV[1]){ next; }
		if ($debug == 1){ print "Processing msdid: $wasabi_tubs_m365->[$u][0]\n"; }

		&wasabi_api_get_totalusage_and_update_from_msdid($wasabi_tubs_m365->[$u][0], 1);

	}


	# UPDATE M365 WASABI TUB USAGES (IMMUTABLE)
	my $query = "SELECT 
					MemberStorageDetails.id,MemberStorageDetails.userid FROM MemberStorageDetails 
				INNER JOIN 
					WasabiAccountsM365 ON(MemberStorageDetails.userid = WasabiAccountsM365.userid)
				WHERE 
					type='vo365' AND MemberStorageDetails.isEnabled='1' AND WasabiAccountsM365.isEnabled='1' AND isImmutable='1' AND isByo='0'";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	my $wasabi_tubs_m365_immut = $sth->fetchall_arrayref();

	print "\n[+] Processing M365 Wasabi Buckets [Immutable]\n\n";

	for my $u (0..$#{$wasabi_tubs_m365_immut}){

		my $sub_userid = $wasabi_tubs_m365_immut->[$u][1];
		if ($ARGV[1] ne '' && $sub_userid != $ARGV[1]){ next; }
		if ($debug == 1){ print "Processing msdid: $wasabi_tubs_m365_immut->[$u][0]\n"; }

		&wasabi_api_get_totalusage_and_update_from_msdid($wasabi_tubs_m365_immut->[$u][0], 1);

	}
}
sub remove_disabled_M365_wasabi
{
	# REMOVE ANY M365 WASABI TUBS
	my $query = "SELECT 
					MemberStorageDetails.id,MemberStorageDetails.userid,isImmutable,isByo FROM MemberStorageDetails 
				INNER JOIN 
					WasabiAccountsM365 ON(MemberStorageDetails.userid = WasabiAccountsM365.userid)
				WHERE 
					type='vo365' AND MemberStorageDetails.hasBeenRemoved='2' AND MemberStorageDetails.isEnabled='0' AND WasabiAccountsM365.isEnabled='1'";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	my $wasabi_tubs_m365_del = $sth->fetchall_arrayref();

	print "\n[+] Processing M365 Wasabi Buckets to be removed\n\n";

	for my $u (0..$#{$wasabi_tubs_m365_del}){

		my $sub_userid = $wasabi_tubs_m365_del->[$u][1];
		if ($ARGV[1] ne '' && $sub_userid != $ARGV[1]){ next; }
		if ($debug == 1){ print "Processing msdid: $wasabi_tubs_m365_del->[$u][0]\n"; }

		&wasabi_api_remove_m365_wasabi_account_from_msdid($wasabi_tubs_m365_del->[$u][0],$wasabi_tubs_m365_del->[$u][2],$wasabi_tubs_m365_del->[$u][3]);

	}

	print "\n[+] Done Processing M365 Wasabi Buckets to be removed\n\n";
}
sub cleanup_unused_wacm_accounts
{

	print "\nCleanup starting - looking for things to clean...\n";

	# SYSTEM
	my $query = "
		SELECT msdid,id,deletedDate FROM WasabiAccounts 
		WHERE 
		(
			(
				msdid IN(SELECT id FROM MemberStorageDetails WHERE isEnabled=0) 
				OR msdid IN(SELECT id FROM MemberStorageDetails WHERE userid IN(SELECT userid FROM Members WHERE isEnabled=0))
				OR msdid IN(SELECT id FROM MemberStorageDetails WHERE userid IN(SELECT userid FROM Members WHERE accountid IN(SELECT AccountID FROM Accounts WHERE isEnabled=0)  ))
			)
			AND isEnabled=1
		)
		OR isEnabled=3
	";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	my $unused_wacm = $sth->fetchall_arrayref();

    my $time_to_wait = 1;

	for my $m(0..$#{$unused_wacm}){
        next if $unused_wacm->[$m][2] > (time - 86400);     # SKIP ANY FAILED ATTEMPTS WITHIN LAST DAY
		print "Removing wacm account [msdid: $unused_wacm->[$m][0]]\n";

        $query = "SELECT TOP (1) userid FROM MemberStorageDetails WHERE id='$unused_wacm->[$m][0]' AND type='object'"; 
        $sth = $dbbvaws->prepare($query);
        $sth->execute;
        my ($sub_userid) = $sth->fetchrow();

		$query = "SELECT accountid FROM Members WHERE userid='$sub_userid' AND isEnabled='1'";
		$sth = $dbbvaws->prepare($query);
		$sth->execute;
		my ($sub_accountid) = $sth->fetchrow();

		my $sub_accountownerid = &get_account_owner_from_accountid($sub_accountid);
		my $using_byo = get_is_using_wasabi_byo_from_mspaccountid($sub_accountownerid);
		my $sub_accountownerid_touse = $using_byo == 1 ?  $sub_accountownerid : 0;
		my $status = qbee_wasabi_api_delete_wasabi_acct_from_msdid($unused_wacm->[$m][0],$sub_accountownerid_touse);

        if($status eq 'rate-limit-reached'){$time_to_wait = $time_to_wait * 2;}else{$time_to_wait = 1;}

        # We can only remove 10/min
        sleep($time_to_wait);
	}

}
sub quick_cleanup_unused_wacm_accounts
{

	print "\n[-] Quick Cleanup starting - looking for things to clean...\n";

	# SYSTEM
	my $query = "SELECT msdid,id,accountNum FROM WasabiAccounts WHERE isEnabled=3";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	my $unused_wacm = $sth->fetchall_arrayref();
    
    my $time_to_wait = 1;

	for my $m(0..$#{$unused_wacm}){

		$query = "SELECT userid,serverid FROM MemberStorageDetails WHERE id='$unused_wacm->[$m][0]'";
		$sth = $dbbvaws->prepare($query);
		$sth->execute;
		my ($sub_userid, $sub_serverid) = $sth->fetchrow();
		
		$query = "SELECT accountid FROM Members WHERE userid='$sub_userid' AND isEnabled='1'";
		$sth = $dbbvaws->prepare($query);
		$sth->execute;
		my ($sub_accountid) = $sth->fetchrow();

		my $sub_accountownerid = &get_account_owner_from_accountid($sub_accountid);
		my $using_byo = get_is_using_wasabi_byo_from_mspaccountid($sub_accountownerid);
		my $sub_accountownerid_touse = $using_byo == 1 ?  $sub_accountownerid : 0;

		print "[!] Removing wacm account -3 [msdid: $unused_wacm->[$m][0]] [userid: $sub_userid] [acctnum: $unused_wacm->[$m][2]] [BYO Acccount: $sub_accountownerid_touse]\n";
		my $status = qbee_wasabi_api_delete_wasabi_acct_from_msdid($unused_wacm->[$m][0],$sub_accountownerid_touse);

        if($status eq 'rate-limit-reached'){$time_to_wait = $time_to_wait * 2;}else{$time_to_wait = 1;}

        # We can only remove 10/min
        sleep($time_to_wait);
	}

	print "\n[+] Finished Quick Cleanup\n";
}
sub get_is_using_wasabi_byo_from_mspaccountid
{
	my $sub_accountid = $_[0]; 					# MSPACCOUNTID

	my $query = "SELECT isByoWACM, isByoPulse,isAIO,isBYO FROM MspBackupDetails WHERE accountid='$sub_accountid' AND isEnabled='1'";
	my $sth = $dbbvaws->prepare($query);
	$sth->execute;
	my ($isBYOW,$isBYOV,$isAIO,$isBYO) = $sth->fetchrow();

	return ($isBYO == 1 || $isBYOW == 1) ? 1 : 0;
}
sub add_missing_scout_wacm_accounts
{

    # Find any Scout deployed that did not have WACM account/bucket created as it should have

    # First, find any that didn't have any wacm accounts created
    $sql = "SELECT ScoutDetails.scoutid,MemberStorageDetails.id,ScoutDetails.scoutuserid,MemberStorageDetails.serverid FROM ScoutDetails
    INNER JOIN MemberStorageDetails ON (ScoutDetails.scoutuserid = MemberStorageDetails.userid)
    WHERE type='object' AND subtype='wasabi' AND MemberStorageDetails.isEnabled=1 AND MemberStorageDetails.id NOT IN (SELECT msdid FROM WasabiAccounts ) AND ScoutDetails.isEnabled=1 AND MemberStorageDetails.isEnabled=1";
    my $incomplete_scout_deployments  = $dbbvaws->selectall_arrayref($sql);

    my $time_to_wait = 1;

    for my $i (0..$#{$incomplete_scout_deployments}){

        my $sub_scoutid = $incomplete_scout_deployments->[$i][0];
        my $sub_msdid = $incomplete_scout_deployments->[$i][1];
        my $scout_userid = $incomplete_scout_deployments->[$i][2];
        my $sub_serverid = $incomplete_scout_deployments->[$i][3];

		my $query = "SELECT isScoutv3 FROM ScoutDetails WHERE scoutid='$sub_scoutid'";
		$sth = $dbmeta001->prepare($query);
		$sth->execute;
		my $is_v3 = $sth->fetchrow();
		next if !$is_v3;

		print "[!] Found scout with missing wacm account! (scoutid: $sub_scoutid)\n";

		# GENERATE EMAIL AND A RANDOM PASSWORD
        my $sub_member_email = "pbxscout-$scout_userid\@probax.io";
		require '/home/control-io/www/scripts/server-uniquekeygeneration.pl';
		my $newmemberpassword_wacm = &server_uniquekeygeneration();

		$query = "SELECT accountid FROM Members WHERE userid='$scout_userid' AND isEnabled='1'";
		$sth = $dbbvaws->prepare($query);
		$sth->execute;
		my ($sub_accountid) = $sth->fetchrow();

		my $sub_accountownerid = &get_account_owner_from_accountid($sub_accountid);
		my $using_byo = get_is_using_wasabi_byo_from_mspaccountid($sub_accountownerid);
		my $sub_accountownerid_touse = $using_byo == 1 ?  $sub_accountownerid : 0;
        
        print "[+] Getting info to make tub (scout). Scoutid: $sub_scoutid | Msdid: $sub_msdid | Userid: $scout_userid | Serverid: $sub_serverid | Accountid: $sub_accountid | AccountOwner: $sub_accountownerid_touse | BYO: $using_byo | $sub_member_email => $newmemberpassword_wacm\n";
		
        my $valid_keys = &test_waca_credentials_from_mspaccountid($sub_accountownerid_touse);

        if($valid_keys){

            my ($response_status,$note,$wasabi_account_id) = wasabi_create_subaccount_from_email_pass_serverid_msdid_v2($sub_member_email,$newmemberpassword_wacm,$sub_serverid,$sub_msdid,1,$sub_accountownerid_touse,0);

            # Success means we've created a wasabi account
            if ( $response_status eq 'success' ){
                print "[+] SUCCESS\n";
                # Make immutbale bucket

                my  $wasabi_bucket_exists = my $bucket_name = my $bucket_region = '';

                ( $wasabi_bucket_exists, $bucket_name, $bucket_region)  = &wasabi_create_bucket_from_wasabiaccountid($wasabi_account_id,'true',$sub_accountid);
            }
            else{
                if($response_status eq 'rate-limit-reached'){$time_to_wait = $time_to_wait * 2;}else{$time_to_wait = 1;}

                sleep($time_to_wait);
                print "[-] FAIL\n";
                # Internal log
                &logger_from_userid_logdata("$scout_userid","failed to create WAC subaccount. Failure relating to: $note. | Serverid: $sub_serverid | Msdid: $sub_msdid | AccountOwnerToUseForWAC: $sub_accountownerid_touse | Scoutuserid: $scout_userid | API Status: $response_status | API Response: $wasabi_account_id","","$sub_accountid",1);

                # External log
                &logger_from_userid_logdata("$scout_userid","failed to create WAC subaccount. Failure relating to: $note. | API Status: $response_status","","$sub_accountid",0);

            }

        }
        else{
            print "KEYS NOT VALID... SKIPPING!\n";

        }

    }

}
sub add_triggered_wacm_accounts
{
    my $one_day_ago = time - 86400;

	$query = "
		OPEN SYMMETRIC KEY PWHist
			DECRYPTION BY PASSWORD='$s_k_pwh'
				SELECT id,msdid,accountName,skipBucketCreation,isObjectLocked,CONVERT(VARCHAR(MAX),DECRYPTBYKEY(accountPass)) FROM WasabiAccounts WHERE accountNum='0' AND isEnabled='1'  AND (failedToCreate=0 OR failedToCreate='' OR failedToCreate IS NULL OR failedToCreate > $one_day_ago) ORDER BY id DESC
		CLOSE SYMMETRIC KEY PWHist
		";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	my ($sub_accountstomake) = $sth->fetchall_arrayref();

    for my $i (0..$#{$sub_accountstomake}){

        my $sub_wsbid = $sub_accountstomake->[$i][0];
        my $sub_msdid = $sub_accountstomake->[$i][1];
        my $sub_member_email = $sub_accountstomake->[$i][2];
        my $sub_skip_bucket_creation = $sub_accountstomake->[$i][3];
        my $sub_obj_locked = $sub_accountstomake->[$i][4];
        my $newmemberpassword_wacm = $sub_accountstomake->[$i][5];



		$query = "SELECT userid,serverid FROM MemberStorageDetails WHERE id='$sub_msdid' AND isEnabled='1'";
		$sth = $dbbvaws->prepare($query);
		$sth->execute;
		my ($sub_userid, $sub_serverid) = $sth->fetchrow();
		
		$query = "SELECT accountid FROM Members WHERE userid='$sub_userid' AND isEnabled='1'";
		$sth = $dbbvaws->prepare($query);
		$sth->execute;
		my ($sub_accountid) = $sth->fetchrow();

		my $sub_accountownerid = &get_account_owner_from_accountid($sub_accountid);
		my $using_byo = get_is_using_wasabi_byo_from_mspaccountid($sub_accountownerid);
		my $sub_accountownerid_touse = $using_byo == 1 ?  $sub_accountownerid : 0;
        
        print "[+] Getting info to make tub (nonscout). Msdid: $sub_msdid | Userid: $sub_userid | Serverid: $sub_serverid | Accountid: $sub_accountid | AccountOwner: $sub_accountownerid_touse | BYO: $using_byo | $sub_member_email => $newmemberpassword_wacm\n";
		
        my ($response_status,$note,$wasabi_account_id) = wasabi_create_subaccount_from_email_pass_serverid_msdid_v2($sub_member_email,$newmemberpassword_wacm,$sub_serverid,$sub_msdid,1,$sub_accountownerid_touse,1);

		# Success means we've created a wasabi account
		if ( $response_status eq 'success' ){
			print "[+] SUCCESS\t\t  \n";
			# Make immutbale bucket

			my  $wasabi_bucket_exists = my $bucket_name = my $bucket_region = '';

			if($sub_skip_bucket_creation != 1){
				my $obj_locked = $sub_obj_locked == 1 ? 'true' : 'false';
				( $wasabi_bucket_exists, $bucket_name, $bucket_region)  = &wasabi_create_bucket_from_wasabiaccountid($wasabi_account_id,$obj_locked,$sub_accountid);
			}

		}
		else{
			print "[-] FAIL: $wasabi_account_id";
			# Internal log
			&logger_from_userid_logdata("$sub_userid","failed to create WAC subaccount. Failure relating to: Serverid: $sub_serverid | Msdid: $sub_msdid | AccountOwnerToUseForWAC: $sub_accountownerid_touse | Userid: $sub_userid | API Status: $response_status | API Response: $wasabi_account_id","","$sub_accountid",1);

			# External log
			&logger_from_userid_logdata("$scout_userid","failed to create WAC subaccount.","","$sub_accountid",0);
            
            my $this_epoch = time;
            $query = "UPDATE WasabiAccounts SET failedToCreate='$this_epoch' WHERE msdid='$sub_msdid' AND accountNum='0'";
            $sth = $dbbvaws->prepare($query);
            $sth->execute;

		}

    }

}
sub wasabi_generate_new_keys_and_pass_from_msdid
{

	my $sub_msdid = $_[0];
	
	(my $sub_accountname, my $sub_accountnum, my $sub_accountpass, my $sub_accesskey, my $sub_secretkey, my $sub_msdid, my $obj_lock) = &wasabi_get_accountdetails_from_msdid($sub_msdid);

	if ( $sub_accesskey eq '' || $sub_secretkey eq ''){ return ("failed","db"); }

    $query = "SELECT accountid FROM Members WHERE userid=(SELECT userid FROM MemberStorageDetails WHERE id=$sub_msdid) AND isEnabled='1'";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	my $sub_accountid = $sth->fetchrow();

	# GENERATE A RANDOM PASSWORD
	require '/home/control-io/www/scripts/server-uniquekeygeneration.pl';
	my $new_pass = &server_uniquekeygeneration();

	my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0, SSL_verify_mode => 0x00 },);
	$ua->timeout(60);

	my $sub_url = "https://partner.wasabisys.com/v1/accounts/$sub_accountnum";
	my $sub_body = qq({"ResetAccessKeys":true,"Password": "$new_pass"});

	$query = "SELECT userid,serverid FROM MemberStorageDetails WHERE id='$sub_msdid' AND isEnabled='1'";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	my ($sub_userid, $sub_serverid) = $sth->fetchrow();
	

	my $sub_accountownerid = &get_account_owner_from_accountid($sub_accountid);
	my $using_byo = get_is_using_wasabi_byo_from_mspaccountid($sub_accountownerid);

	my $primary_api_key = my $secondary_api_key = '';
	
	if($using_byo == 1){
		($primary_api_key, $secondary_api_key) = wasabi_get_byoapikeys_from_mspaccountid_v2($sub_accountownerid);
	}
	else{
		($primary_api_key, $secondary_api_key) = &wasabi_get_api_keys();
	}


	my $request = HTTP::Request->new("POST","$sub_url",HTTP::Headers->new(),"$sub_body");
	$request->header('Accept' => 'application/json');
	$request->header('Authorization' => "$primary_api_key");
	$request->header('Content-Type' => 'application/json');
	
	my $response = $ua->request($request);
	
	if ($response->is_success) {

		$response_value = $response->decoded_content;
		my $json_data = from_json($response_value);

        my $access_key = $json_data->{AccessKey};
        my $secret_key = $json_data->{SecretKey};

		my $query = "OPEN SYMMETRIC KEY PWHist
			DECRYPTION BY PASSWORD='$s_k_pwh'
				UPDATE WasabiAccounts SET 
					accessKey=EncryptByKey(Key_GUID('PWHist'),'$access_key'),
					secretKey=EncryptByKey(Key_GUID('PWHist'),'$secret_key'),
					accountPass=EncryptByKey(Key_GUID('PWHist'),'$new_pass'),
					needsKeysRotated='0'
				WHERE msdid='$sub_msdid' AND isEnabled='1'			
			CLOSE SYMMETRIC KEY PWHist";
		$sth = $dbbvaws->prepare($query);
		$sth->execute;

		# return ("$access_key","$secret_key","$new_pass");

	}
	else{
		$response_value = $response->decoded_content;

		my $query = "OPEN SYMMETRIC KEY PWHist
			DECRYPTION BY PASSWORD='$s_k_pwh'
				UPDATE WasabiAccounts SET needsKeysRotated='2' WHERE msdid='$sub_msdid' AND isEnabled='1'			
			CLOSE SYMMETRIC KEY PWHist";
		$sth = $dbbvaws->prepare($query);
		$sth->execute;

		&connect_db_logs001();

		# LOG THIS INTERNALLY
		$updatetime = time;
		$log_data = "Failed to get new Wasabi Keys. API Response: $response_value";
		$query = "INSERT IGNORE INTO TransactionLog (userid,logforaccountid,logforuserid,logtime,logdata,fromip,isHidden) 
				VALUES ( ?,?,?,?,?,?,?)";
		$sth = $dbbvlogs001->prepare($query);
        $sth->bind_param(1, 0);
        $sth->bind_param(2, $sub_accountid);
        $sth->bind_param(3, $sub_userid);
        $sth->bind_param(4, $updatetime);
        $sth->bind_param(5, $log_data);
        $sth->bind_param(6, 0);
        $sth->bind_param(7, 1);
		$sth->execute;

		&disconnect_db_logs001();

		# return ("failed","api","err");
	
	}

}
sub reset_keys
{

	$query = "
		OPEN SYMMETRIC KEY PWHist
			DECRYPTION BY PASSWORD='$s_k_pwh'
				SELECT id,msdid FROM WasabiAccounts WHERE needsKeysRotated='1' AND isEnabled='1' ORDER BY id DESC
		CLOSE SYMMETRIC KEY PWHist
		";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	my ($sub_accounts_to_reset) = $sth->fetchall_arrayref();

	for my $a (0..$#{$sub_accounts_to_reset}){

		&wasabi_generate_new_keys_and_pass_from_msdid($sub_accounts_to_reset->[$a][1]);

	}

}

sub test_waca_credentials_from_mspaccountid
{
	my $msp_accountid = $_[0];

	use JSON;
	use LWP::UserAgent;
	use URI::Encode qw(uri_encode uri_decode);

    my $using_byo = &get_is_using_wasabi_byo_license_from_mspaccountid($msp_accountid);

	$api_server = "partner.wasabisys.com";

	my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0, SSL_verify_mode => 0x00 },);
	$ua->timeout(60);

	my $sub_url = 'https://'.$api_server.'/v1/accounts';
	my $primary_api_key = my $secondary_api_key = '';

	# IF WE'VE BEEN SENT AN MSP ACCOUNT ID - THIS MEANS WE'RE ONBOARDING WITH BYO  - USE RELEVANT KEYS
	if($using_byo){
		($primary_api_key, $secondary_api_key) = &wasabi_get_byoapikeys_from_mspaccountid($msp_accountid);
	}
	else{
		($primary_api_key, $secondary_api_key) = &wasabi_get_api_keys();
	}

	my $request = HTTP::Request->new("GET","$sub_url",HTTP::Headers->new());
	$request->header('Accept' => 'application/json');
	$request->header('Authorization' => "$primary_api_key");
	$request->header('Content-Type' => 'application/json');

	my $response = $ua->request($request);
	
	if ($response->is_success) {
        return 1;
    }
    else{
        return 0;
    }

}
######################
# MAIN PROGRAM START #
######################

if ($ARGV[0] eq 'cleanup'){
	$debug = 1;
	quick_cleanup_unused_wacm_accounts();
}
elsif ($ARGV[0] eq 'wacm-quickactions'){
	$debug = 1;
	add_missing_scout_wacm_accounts();
	add_triggered_wacm_accounts();
	reset_keys();
}
else{

	# UPDATE WASABI TUB USAGES
	my $query = "SELECT id,userid,totalusage FROM MemberStorageDetails WHERE type='object' AND subtype='wasabi' AND isEnabled='1'";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	my $wasabi_tubs = $sth->fetchall_arrayref();

	print "\n[+] Processing Standard Wasabi Buckets \n\n";
	for my $t (0..$#{$wasabi_tubs}){

		my $sub_msdid = $wasabi_tubs->[$t][0];
		my $sub_userid = $wasabi_tubs->[$t][1];
		my $sub_usage = $wasabi_tubs->[$t][2];

		if ($ARGV[1] ne '' && $sub_userid != $ARGV[1]){ next; }
		if ($debug == 1){ print "Processing msdid: $sub_msdid\n"; }

		&wasabi_api_get_totalusage_and_update_from_msdid($sub_msdid);

	}

	# CLEANUP - DISABLE ANY TUBS READY FOR DELETION
	my $now_epoch = time;
	my $past_day_epoch = time - 86400;
	my $past_90day_epoch = time - ( 86400 * 90 );

	# GET ENABLED TUBS SCHEDULED FOR DELETION - AND PAST 90DAYs
	my $query = "SELECT id,userid,totalusage FROM MemberStorageDetails WHERE id IN (SELECT msdid FROM WasabiAccounts WHERE isEnabled='0' AND deletedDate < $past_90day_epoch ) AND type='object' AND subtype='wasabi' AND isEnabled='1'";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	my $tubs_sched_to_del = $sth->fetchall_arrayref();

	for my $tub ( 0..$#{$tubs_sched_to_del} ){

		my $query = "UPDATE MemberStorageDetails SET isEnabled='0' WHERE id='$tubs_sched_to_del->[$tub][0]' AND isEnabled='1' AND type='object' AND subtype='wasabi'";
		if ($debug == 1){ print "Disabled msdid: $tubs_sched_to_del->[$tub][0]\n$query\n\n"; }
		$sth = $dbbvaws->prepare($query);
		$sth->execute;

		# DISABLE THE GENERIC USER THAT WAS CREATED AS WELL
		$query = "UPDATE Members SET isEnabled='0' WHERE userid=(SELECT userid FROM MemberStorageDetails WHERE id='$tubs_sched_to_del->[$tub][0]' AND type='object' AND subtype='wasabi')";
		$sth = $dbbvaws->prepare($query);
		$sth->execute;

	}

	# GET ENABLED TUBS SCHEDULED FOR DELETION - AND NEVER HAD DATA - DELETE STRAIGHTAWAY
	my $query = "SELECT id,userid,totalusage FROM MemberStorageDetails WHERE id IN (SELECT msdid FROM WasabiAccounts WHERE isEnabled='0' AND deletedDate < $past_day_epoch) AND type='object' AND subtype='wasabi' AND ( totalusage='0' OR totalusage='' OR totalusage IS NULL ) AND isEnabled='1'";
	$sth = $dbbvaws->prepare($query);
	$sth->execute;
	my $tubs_to_del = $sth->fetchall_arrayref();

	for my $t (0..$#{$tubs_to_del}){

		# BEFORE WE DO A NEXT DAY TUB REMOVAL FOR TUBS THAT DON'T CURRENTLY HAVE USAGE, LET'S MAKE SURE THERE HAS _NEVER_ BEEN STORAGE DETECTED IN THE PAST IN CASE THEY ONLY JUST REMOVED DATA => CHECK DataPoint [PaddedBytes]
		my $query = "SELECT value FROM DataPoints WHERE datasourceid=(SELECT datasourceid FROM DataSources WHERE appliesToStorageTub='1' AND value='$tubs_to_del->[$t][0]' AND globaldatasourceid=1200) AND value > 0 LIMIT 1;";
		if ($debug == 1){ print "Checking if msdid is ready for immeidiate deletion.  msdid: $tubs_to_del->[$t][0]\n$query\n\n"; }
		$sth = $dbmeta001->prepare($query);
		$sth->execute;
		my $detected_storage = $sth->fetchrow();

		# IF THEY HAVE HAD STORAGE AT SOME POINT, SKIP IMMEDIATE DELETION SO THEY WILL HAVE TO WAIT TO 90 DAYS ARE MET
		if($detected_storage > 0){ next;}

		# IF NO DATA HAS EVER BEEN ADDED TO THIS TUB - WE'RE GOOD FOR A NEXT-DAY DELETE
		my $query = "UPDATE MemberStorageDetails SET isEnabled='0' WHERE id='$tubs_to_del->[$t][0]' AND isEnabled='1' AND type='object' AND subtype='wasabi'";
		if ($debug == 1){ print "Disabled msdid: $tubs_to_del->[$t][0]\n$query\n\n"; }
		$sth = $dbbvaws->prepare($query);
		$sth->execute;

		# DISABLE THE GENERIC USER THAT WAS CREATED AS WELL
		$query = "UPDATE Members SET isEnabled='0' WHERE userid=(SELECT userid FROM MemberStorageDetails WHERE id='$tubs_to_del->[$t][0]' AND type='object' AND subtype='wasabi')";
		$sth = $dbbvaws->prepare($query);
		$sth->execute;

	}

	# NON-M365 USAGES AND SCHEDULED DELETIONS DONE
	update_M365_wasabi_usages();
	remove_disabled_M365_wasabi();
	cleanup_unused_wacm_accounts();


}




1;


