PACKAGE "CMN_CREATE_MONEY_SCREEN_TEMP" AS
-- *****************************************************************************
--      $Id: PACKAGE.CMN_CREATE_MONEY_SCREEN_TEMP.pls 3553 2008-05-29 14:23:30Z a.hira $
--      顧客名            ：三谷産業株式会社
--      システム名        ：Ｌ２プロジェクト
--      業種名（事業部名）：共通
--      プログラム名      ：入金一覧照会TEMP作成
--      All rights reserved, Copyright (c) MITANI SANGYO Co.,Ltd. 2008-
-- *****************************************************************************

    -- 入金一覧照会TEMP作成
    PROCEDURE CREATE_MONEY_SCREEN_TEMP(
         I_TOP_DEPT_NO          IN	VARCHAR2	-- 1.最上位部門番号（必須）
        ,I_MONEY_DATE_S         IN	VARCHAR2	-- 2.開始入金日付（必須）
        ,I_MONEY_DATE_E         IN	VARCHAR2	-- 3.終了入金日付（必須）
        ,I_DUE_DEPT_NO          IN	VARCHAR2	-- 4.担当部門番号
        ,I_DUE_EMP_CODE         IN	VARCHAR2	-- 5.担当社員コード
 		,I_INVOICE_TO_NO		IN	VARCHAR2	-- 6.請求先番号
		,I_INVOICE_TO_ACCO_NO	IN	VARCHAR2	-- 7.請求先口座番号
		,I_ACCOUNT_SUBJECT_CODE	IN	VARCHAR2	-- 8.勘定科目コード
		,I_DENOMINATION_TYPE	IN	VARCHAR2	-- 9.金種区分
		,I_ADD_UP_FLG			IN	VARCHAR2	--10.消込完了フラグ
								-- (TRUE:消込済 FALSE:未消込 NULL:条件にしない)
		,I_PARTNER_UNASSIGN_FLG	IN	VARCHAR2	--11.取引先未割付分のみフラグ
								-- (TRUE:取引先未割付分のみ FALSE:条件にしない)
        ,I_DEPT_UNASSIGN_FLG     IN	VARCHAR2	--12.部門未割付分のみフラグ
                                -- (TRUE:部門未割付分のみ FALSE:条件にしない)
        
        
    );
END "CMN_CREATE_MONEY_SCREEN_TEMP";

