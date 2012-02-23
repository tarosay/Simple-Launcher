------------------------------------------
--超簡易ランチャ Ver1.1
------------------------------------------
--関数宣言--------------------------------
main={}					--mainメソッド
readtxt={}				--/luarida/launcher.txtファイルを読み込みます
selectmenu={}		--実行するプログラムを選択します
getHttp={}				--http.getを用いてファイルを取得します
setDirection={}		-- 縦横の自動設定

--グローバル変数宣言----------------------
Launchertxt = system.getCardMnt().."/luarida/launcher.txt"	--ランチャデータファイル
LauncherFile={}
LuaridaPath = system.getCardMnt().."/luarida"		--ランチャファイルを保存しているパス
------------------------------------------
mt={}
mt.__newindex=function(mtt,mtn,mtv)
	dialog( "Error Message", "宣言していない変数 "..mtn.." に値を入れようとしています", 0 )
	toast("画面タッチで実行を続けます", 1)
	touch(3)
end
mt.__index=function(mtt,mtn)
	dialog( "Error Message", "変数 "..mtn.." は宣言されていません", 0 )
	toast("画面タッチで実行を続けます", 1)
	touch(3)
end
setmetatable(_G,mt)
--------以下が実プログラム----------------
------------------------------------------
-- 縦横の自動設定
------------------------------------------
function setDirection()
local i
local ax,ay
	sensor.setdevAccel( 1 )	--加速度センサ起動
	for i=1,32 do
		ax, ay = sensor.getAccel()
	end
	sensor.setdevAccel( 0 )	--加速度センサオフ
	if( ax<5 and ay>5 )then
		system.setScreen(1)   --縦向きに変更
			--内部グラフィック画面設定の変更
			local w,h = canvas.getviewSize()
			canvas.setMainBmp( w, h )
	end
 end
------------------------------------------
--/luarida/launcher.txtファイルを読み込みます
------------------------------------------
function readtxt()
local fp
	fp = io.open( Launchertxt, "r" )		--ランチャデータファイルを開きます
	if( not(fp) )then
		--ランチャデータファイルが無かったので、自動生成します
		fp = io.open( Launchertxt, "w+" )
		if( not(fp) )then
			dialog( Launchertxt.." がオープンできません","変更しないで終了します", 1 )
			return -1
		else
			LauncherFile[1] = system.getAppPath().."/slauncher.lua"
			fp:write( LauncherFile[1] .."\n" )
			io.flush()
			io.close( fp )
			return 0
		end
	else
		--ランチャデータを読み込みます
		local n = 1
		while(true)do
			local str = fp:read("*l")         --1行読み込み
			if( str==nil )then break end      --読込むデータが無ければ終了
			str = string.gsub( str,"\r","" )  --改行コードを外す
			LauncherFile[n] = str
			n = n + 1
		end
		io.close(fp)
	end
	return 0
end
------------------------------------------
--実行するプログラムを選択します
------------------------------------------
function selectmenu()
local i
	item.clear()
	for i=1, #LauncherFile do
		item.add( LauncherFile[i], 0 )
	end	
	return item.list("実行するプログラムを選んでください")
end
------------------------------------------
--http.getを用いてファイルを取得します
-- Error:-1
------------------------------------------
function getHttp( url, putFilename )

	http.get( url, putFilename )
	local s = http.status()
	while( s==0 )do	--ファイルを取得するまで待ちます。
		s = http.status()
	end
	if( s~=1 )then
		if( s==2 )then
			dialog( "取得エラーです" , "URLのプロトコルが開けません", 1 )
		elseif( s==3 )then
			dialog( "取得エラーです" , "接続できない、またはURLが見つかりません", 1 )
		elseif( s==4 )then
			dialog( "取得エラーです" , "データ取得時にエラーが発生しました", 1 )
		elseif( s==5 )then
			dialog( "取得エラーです" , "保存ファイルが開けませんでした", 1 )
		elseif( s==6 )then
			dialog( "取得エラーです" , "接続がタイムアウトしました", 1 )
		else
			dialog( "取得エラーです" , "httpスレッド起動時にエラーが発生しました", 1 )
		end
		return -1
	end
	return 0
end
------------------------------------------
--メインプログラム
------------------------------------------
function main()
	setDirection()	-- 縦横画面の自動設定
	toast( "超簡易ランチャ V1.1" )

	--ランチャデータを読み込みます
	if( readtxt()==-1 )then
		dialog( "","データエラーで終了します", 1 )
		return
	end

	--実行するファイルを選びます
	local num = selectmenu()

	if( num==0 )then
		dialog( "", "超簡易ランチャを終了します",1)
		system.exit()
		return
	end

	--runしないフラグをセットします
	local notRunFlg = 0
	--LauncherFile[num]の先頭が '*'のときは、'*'を消します。
	if( LauncherFile[num]:sub(1,1)=="*")then
		LauncherFile[num] = LauncherFile[num]:sub(2)
		notRunFlg = 1
	end

	--先頭がhttp://かどうか調べます
	if( string.sub( LauncherFile[num],1,7)=="http://" )then
		--http://だった
		local filename = LauncherFile[num]
		for i=1, string.len( filename ) do
			local cname = string.sub( filename, -i )
			if( string.sub( cname, 1, 1 )=="/" )then
				filename = string.sub( cname, 2 )
				break
			end			
		end
		
		--filenameをダウンロードします
		toast( filename.." のダウンロード中です" )
		if( getHttp( LauncherFile[num],  LuaridaPath.."/"..filename )==-1)then
			toast( "エラーが発生したので終了します" )
			return
		end
		
		if( notRunFlg==0)then
			system.setrun( LuaridaPath.."/"..filename )	--実行ファイルをセットします
		else
			--ダウンロードしたファイルを起動しないので、もう一度超簡易エディタを起動します。
			system.setrun(  system.getAppPath().."/slauncher.lua" )
		end
	else
	
		--通常のluaファイルだった
		system.setrun( LauncherFile[num] )	--実行ファイルをセットします
	end
end
main()
