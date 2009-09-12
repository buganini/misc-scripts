<?php
"
This script convert Ignition's save result (c2c) to CDBurnerXP's file list (DXP format)
Ignition	: http://www.kcsoftwares.com/index.php?ignition
CDBurnerXP	: http://cdburnerxp.se/
";
function walk(&$data,$pad){
	global $out;
	foreach($data as $f){
		if(isset($f['realpath'])){
			if(!empty($f['child'])){
				fwrite($out,$pad.'<dir name="'.$f['name'].'" path="'.$f['path'].'" realpath="'.$f['realpath'].'">'."\n");
				walk($f['child'],$pad.'  ');
				fwrite($out,$pad."</dir>\n");				
			}else{
				fwrite($out,$pad.'<dir name="'.$f['name'].'" path="'.$f['path'].'" realpath="'.$f['realpath'].'" />'."\n");
			}
		}else{
			fwrite($out,$pad.'<file name="'.$f['name'].'" path="'.$f['path'].'" />'."\n");
		}
	}
}
for($i=1;$i<count($argv);++$i){
	$out=fopen($argv[$i].'.dxp','w');
	fwrite($out,'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<!DOCTYPE layout PUBLIC "http://www.cdburnerxp.se/help/data.dtd" "">
<?xml-stylesheet type=\'text/xsl\' href=\'http://www.cdburnerxp.se/help/compilation.xsl\'?>
<layout type="Data">
  <compilation name="Disc">
    <dir name="Disc" path="\" realpath="">
');
	
	$prefix='M:\\';

	$data=array();
	
	$off=strlen($prefix);
	$list=file_get_contents($argv[$i]);
	$list=str_replace("\r\n","\n",$list);
	$list=explode("\n",$list);
	foreach($list as $rec){
		unset($dive);
		$dive=&$data;
		if($rec[0]==';') continue;
		$rec=str_replace('&','&amp;',$rec);
		if(strpos($rec,$prefix)===0){
			list($fullpath,$nul)=explode("\t",$rec);
			$path=substr($fullpath,$off);
			$path=explode('\\',$path);
			$p=array();
			$tok=array_shift($path);
			while(count($path)>0){
				$p[]=$tok;
				if(!isset($dive[$tok])){
					$dive[$tok]=array('name'=>$tok,'path'=>implode('\\',$p),'realpath'=>$prefix.implode('\\',$p));
				}
				if(!isset($dive[$tok]['child'])){
					$dive[$tok]['child']=array();
				}
				unset($tmp);
				$tmp=&$dive[$tok]['child'];
				unset($dive);
				$dive=&$tmp;
				unset($tmp);
				$tok=array_shift($path);
			}
			$dive[$tok]=array('name'=>$tok,'path'=>$fullpath);
		}else{
			list($tmp,$nul)=explode("\t",$rec);
			$fullpath=$nul.$tmp;
			$path=explode('\\',$fullpath);
			$p=array();
			$tok=array_shift($path);
			while(count($path)>0){
				$p[]=$tok;
				if(!isset($dive[$tok])){
					$dive[$tok]=array('name'=>$tok,'path'=>implode('\\',$p),'realpath'=>$prefix.implode('\\',$p));
				}
				if(!isset($dive[$tok]['child'])){
					$dive[$tok]['child']=array();
				}
				unset($tmp);
				$tmp=&$dive[$tok]['child'];
				unset($dive);
				$dive=&$tmp;
				unset($tmp);
				$tok=array_shift($path);
			}
			$dive[$tok]=array('name'=>$tok,'path'=>$fullpath,'realpath'=>$prefix.$fullpath);
		}
	}
	#print_r($data);
	
	walk($data,'      ');
	fwrite($out,'    </dir>
  </compilation>
</layout>
');
	fclose($out);
}
?>