<?php

$username = '9WNa8V2P86Q'; // = Auth-Key
$password = '';

$ch = curl_init();
curl_setopt($ch,CURLOPT_VERBOSE,1);
curl_setopt($ch, CURLOPT_URL, 'https://www.thomas-krenn.com/api/v1/monitoring/heartbeat');
curl_setopt($ch, CURLOPT_USERPWD, "{$username}:{$password}");
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, FALSE);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, array());

curl_exec($ch);
$status = curl_getinfo($ch, CURLINFO_HTTP_CODE);

var_dump ($status);




?>
