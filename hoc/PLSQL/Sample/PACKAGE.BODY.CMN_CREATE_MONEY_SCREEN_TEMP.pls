CREATE OR REPLACE PACKAGE BODY "CMN_CREATE_MONEY_SCREEN_TEMP" AS
-- ****************************************************************************
--	$Id: PACKAGE.BODY.CMN_CREATE_MONEY_SCREEN_TEMP.pls 11863 2014-04-08 06:58:46Z hungmh $
--	顧客名			：三谷産業株式会社
--	システム名		：Ｌ２プロジェクト
--	業種名			：共通
--	プログラム名 	：入金一覧照会TEMP作成
--	All rights reserved, Copyright (c) MITANI SANGYO Co.,Ltd. 2008-
-- ****************************************************************************

-- ----------------------------------------------------------------------------
--	定数
-- ----------------------------------------------------------------------------

	-- プログラム名
	C_PROGRAM_NAME	CONSTANT	VARCHAR2(100)	:=
												'入金一覧照会TEMP作成';
	-- パッケージ名
	C_PACKAGE_NAME	CONSTANT	VARCHAR2(30)	:= 'CMN_CREATE_MONEY_SCREEN_TEMP';

	LOGICAL_ERROR	EXCEPTION;				-- 論理エラー
	EXPECTED_ERROR	EXCEPTION;				-- 予期したエラー

-- ----------------------------------------------------------------------------
--	広域変数
-- ----------------------------------------------------------------------------

	-- 引数格納用
	P_TOP_DEPT_NO				VARCHAR2(4000);	-- 1.最上位部門番号
	P_MONEY_DATE_S				VARCHAR2(4000);	-- 2.開始入金日付(YYYYMMDD)
	P_MONEY_DATE_E				VARCHAR2(4000);	-- 3.終了入金日付(YYYYMMDD)
	P_DUE_DEPT_NO				VARCHAR2(4000);	-- 4.担当部門番号
	P_DUE_EMP_CODE         		VARCHAR2(4000);	-- 5.担当社員コード
	P_INVOICE_TO_NO				VARCHAR2(4000);	-- 6.請求先番号
	P_INVOICE_TO_ACCO_NO		VARCHAR2(4000);	-- 7.請求先口座番号
	P_ACCOUNT_SUBJECT_CODE		VARCHAR2(4000);	-- 8.勘定科目コード
	P_DENOMINATION_TYPE			VARCHAR2(4000);	-- 9.金種区分
	P_ADD_UP_FLG				VARCHAR2(4000);	--10.消込完了フラグ
	P_PARTNER_UNASSIGN_FLG		VARCHAR2(4000);	--11.取引先未割付分のみフラグ
	P_DEPT_UNASSIGN_FLG         VARCHAR2(4000);	--12.部門未割付分のみフラグ

	-- その他広域変数
	V_JOB_ID					NUMBER	:= NULL;	-- ジョブID
	V_INPUT_CNT					NUMBER	:= 0;		-- 取得件数
	V_OUTPUT_CNT				NUMBER	:= 0;		-- 作成件数

	V_MONEY_ADD_UP_DETAIL_CNT				NUMBER	:= 0;		-- 入金消込明細の件数

	-- 入金差額種類区分(手数料)
	C_MONEY_DIFF_SORT_TYPE_FEES	CONSTANT	VARCHAR2(4) := '0001';

-- ----------------------------------------------------------------------------
--	サブプログラム宣言
-- ----------------------------------------------------------------------------

-- 入金一覧を構築する
PROCEDURE CREATE_MONEY_SCREEN_TEMP;

--カーソル定義用動的SQL文字列を組み立てる
FUNCTION EDIT_SCREEN_SQL RETURN VARCHAR2;

-- 名称翻訳を行う
PROCEDURE UPDATE_NAMES_FOR_SCR(
	IO_R_TEMP				IN OUT NOCOPY MONEY_SCREEN_TEMP%ROWTYPE
);

--	入金差額を取得し、入金差額・入金差額消費税を編集する
PROCEDURE GET_MONEY_DIFF (
	IO_R_TEMP					IN OUT	MONEY_SCREEN_TEMP%ROWTYPE
	);

--  入金消込明細を取得する
PROCEDURE GET_MONEY_ADD_UP_DETAIL(
	I_MONEY_ID				IN	MONEY_ADD_UP_DETAIL.MONEY_ID%TYPE
	,O_FINAN_LINKED_FLG		OUT NOCOPY MONEY_ADD_UP_DETAIL.FINAN_LINKED_FLG%TYPE
	);

--  入金消込関連を取得し、消込フラグを編集する
PROCEDURE EDIT_ADDUP_FLG(
	IO_R_TEMP					IN OUT	MONEY_SCREEN_TEMP%ROWTYPE
	);

-- ----------------------------------------------------------------------------
--	サブプログラム本体
-- ----------------------------------------------------------------------------

-- ****************************************************************************
--	入金一覧照会TEMP作成
--	このプロシジャは、Javaアプリケーションから呼ばれることを前提としています。
--	トランザクション管理は呼び出し元で行ってください。
--
--	入金から、一時表(入金一覧照会TEMP)のデータを作成する
--	また、各金額を編集するため、入金差額、入金消込明細を索引する。
--
-- @PARAM	I_TOP_DEPT_NO			最上位部門番号（必須）
-- @PARAM	I_MONEY_DATE_S			開始入金日付（必須）
-- @PARAM	I_MONEY_DATE_E			終了入金日付（必須）
-- @PARAM	I_DUE_DEPT_NO			担当部門番号
-- @PARAM	I_DUE_EMP_CODE			担当社員コード
-- @PARAM	I_INVOICE_TO_NO			請求先番号
-- @PARAM	I_INVOICE_TO_ACCO_NO	請求先口座番号
-- @PARAM	I_ACCOUNT_SUBJECT_CODE	勘定科目コード
-- @PARAM	I_DENOMINATION_TYPE		金種区分
-- @PARAM	I_ADD_UP_FLG			消込完了フラグ
--									(TRUE:消込済 FALSE:未消込 NULL:条件にしない)
-- @PARAM	I_PARTNER_UNASSIGN_FLG	取引先未割付分のみフラグ
--									(TRUE:取引先未割付分のみ FALSE:条件にしない)
-- @PARAM	I_DEPT_UNASSIGN_FLG     部門未割付分のみフラグ
--                                  (TRUE:部門未割付分のみ FALSE:条件にしない)
-- ****************************************************************************
PROCEDURE CREATE_MONEY_SCREEN_TEMP(
	 I_TOP_DEPT_NO          IN	VARCHAR2
	,I_MONEY_DATE_S         IN  VARCHAR2
	,I_MONEY_DATE_E         IN  VARCHAR2
	,I_DUE_DEPT_NO          IN	VARCHAR2
	,I_DUE_EMP_CODE         IN	VARCHAR2
	,I_INVOICE_TO_NO		IN	VARCHAR2
	,I_INVOICE_TO_ACCO_NO	IN	VARCHAR2
	,I_ACCOUNT_SUBJECT_CODE	IN	VARCHAR2
	,I_DENOMINATION_TYPE	IN	VARCHAR2
	,I_ADD_UP_FLG			IN	VARCHAR2
	,I_PARTNER_UNASSIGN_FLG	IN	VARCHAR2
    ,I_DEPT_UNASSIGN_FLG    IN	VARCHAR2
) AS

	C_PROC_NAME		CONSTANT	VARCHAR2(30)	:= 'CREATE_MONEY_SCREEN_TEMP';

	V_MSG						VARCHAR2(4000);		-- エラーメッセージ

BEGIN

	-- 件数初期化
	V_INPUT_CNT := 0;
	V_OUTPUT_CNT := 0;

	-- ジョブIDを取得（グローバル編集に格納）
	V_JOB_ID := CMN.GET_JOB_ID;

	-- プログラム開始情報をログに出力
	CMN.DEBUG (V_JOB_ID, C_PACKAGE_NAME, '開始：【' || C_PROGRAM_NAME || '】');

	-- パラメタを変数に格納
	P_TOP_DEPT_NO				:= I_TOP_DEPT_NO;
	P_MONEY_DATE_S				:= I_MONEY_DATE_S;
	P_MONEY_DATE_E				:= I_MONEY_DATE_E;
	P_DUE_DEPT_NO				:= I_DUE_DEPT_NO;
	P_DUE_EMP_CODE				:= I_DUE_EMP_CODE;
	P_INVOICE_TO_NO				:= I_INVOICE_TO_NO;
	P_INVOICE_TO_ACCO_NO		:= I_INVOICE_TO_ACCO_NO;
	P_ACCOUNT_SUBJECT_CODE		:= I_ACCOUNT_SUBJECT_CODE;
	P_DENOMINATION_TYPE			:= I_DENOMINATION_TYPE;
	P_ADD_UP_FLG				:= I_ADD_UP_FLG;
	P_PARTNER_UNASSIGN_FLG		:= I_PARTNER_UNASSIGN_FLG;
    P_DEPT_UNASSIGN_FLG         := I_DEPT_UNASSIGN_FLG;

	-- パラメタ表示（デバッグ用）
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'最上位部門番号　　　　　 (' || P_TOP_DEPT_NO || ')');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'開始入金日付(YYYYMMDD)   (' || P_MONEY_DATE_S || ')');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'終了入金日付(YYYYMMDD)   (' || P_MONEY_DATE_E || ')');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'担当部門番号　　　    　 (' || P_DUE_DEPT_NO || ')');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'担当社員コード　　　　   (' || P_DUE_EMP_CODE || ')');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'請求先番号               (' || P_INVOICE_TO_NO || ')');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'請求先口座番号　　　　　 (' || P_INVOICE_TO_ACCO_NO || ')');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'勘定科目コード　　　     (' || P_ACCOUNT_SUBJECT_CODE || ')');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'金種区分　　　　　　     (' || P_DENOMINATION_TYPE || ')');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'消込完了フラグ　         (' || P_ADD_UP_FLG || ')');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'取引先未割付分のみフラグ (' || P_PARTNER_UNASSIGN_FLG || ')');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'部門未割付分のみフラグ   (' || P_DEPT_UNASSIGN_FLG || ')');

	-- 入金一覧照会TEMPを構築する
	CREATE_MONEY_SCREEN_TEMP;

	-- 件数ログ表示
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME, '読込件数 : ' ||
			TO_CHAR(V_INPUT_CNT,  '999,999') || ' 件');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME, '出力件数 : ' ||
			TO_CHAR(V_OUTPUT_CNT,  '999,999') || ' 件');

	-- プログラム終了情報をログに出力
	CMN.DEBUG (V_JOB_ID, C_PACKAGE_NAME, '終了：【' || C_PROGRAM_NAME || '】');

EXCEPTION
	WHEN OTHERS THEN
		V_MSG		:= '異常終了しました。';
		CMN_EXCEPTION.RAISE_APP_ERROR (
				 V_JOB_ID, C_PROGRAM_NAME, C_PACKAGE_NAME
				,C_PROC_NAME, SQLCODE, SQLERRM
				,V_MSG
		);
END CREATE_MONEY_SCREEN_TEMP;

-- ****************************************************************************
--	入金一覧照会TEMPを構築する
--	@PARAM	なし
-- ****************************************************************************
PROCEDURE CREATE_MONEY_SCREEN_TEMP
IS

	C_PROC_NAME		CONSTANT	VARCHAR2(30)	:=
											'CREATE_MONEY_SCREEN_TEMP';
	V_MSG						VARCHAR2(4000);		-- エラーメッセージ

	V_SQL						VARCHAR2(32767);	-- 動的SQL編集用

	-- 入金一覧検索用カーソル
	TYPE CUR_SCREEN_TYPE		IS REF CURSOR;
	CUR_MONEY_SC				CUR_SCREEN_TYPE;

	-- 入金一覧照会TEMPレコード
	R_TEMP						MONEY_SCREEN_TEMP%ROWTYPE;

BEGIN

	-- 動的SQLを使用してカーソルループ
	V_SQL := EDIT_SCREEN_SQL;
	OPEN CUR_MONEY_SC FOR V_SQL;

	LOOP

		-- 初期化
		DM_MONEY_SCREEN_TEMP.INIT(R_TEMP);

		FETCH CUR_MONEY_SC INTO
			 R_TEMP.MONEY_ID
			,R_TEMP.TOP_DEPT_NO
			,R_TEMP.MONEY_NO
			,R_TEMP.UNCONFIRM_INVOICE_TO_FLG
			,R_TEMP.INVOICE_TO_NO
			,R_TEMP.INVOICE_TO_ACCOUNT_NO
			,R_TEMP.INVOICE_TO_ASSUMED_NAME
			,R_TEMP.DUE_DEPT_NO
			,R_TEMP.DUE_EMP_CODE
			,R_TEMP.TRADE_DATE
			,R_TEMP.DENOMINATION_TYPE
			,R_TEMP.MONEY_AMOUNT
			,R_TEMP.ACCOUNT_SUBJECT_CODE
			,R_TEMP.SUBSIDY_SUBJECT_CODE
			,R_TEMP.REMARK1
			,R_TEMP.REMARK2
			,R_TEMP.MAKE_PAY_REQ_NO;
		EXIT WHEN CUR_MONEY_SC%NOTFOUND;

		-- 取得件数カウントアップ
		V_INPUT_CNT := V_INPUT_CNT + 1;

		-- 入金消込明細を取得する
		GET_MONEY_ADD_UP_DETAIL(R_TEMP.MONEY_ID, R_TEMP.FINAN_LINKED_FLG);

		-- 入金差額と手数料を取得する
		GET_MONEY_DIFF(R_TEMP);

		-- 入金消込関連を取得し、消込フラグを編集する
		EDIT_ADDUP_FLG(R_TEMP);

		-- 以下の場合、入金一覧照会TEMPを作成する
		-- パラメタ.消込完了ﾌﾗｸﾞ＝NULL
		-- または (ﾊﾟﾗﾒﾀ.消込完了ﾌﾗｸﾞ＝TRUE(消込済) かつ 入金消込明細が取得可)
		-- または (ﾊﾟﾗﾒﾀ.消込完了ﾌﾗｸﾞ＝FALSE(未消込) かつ 入金消込明細が取得不可)
		IF P_ADD_UP_FLG IS NULL OR P_ADD_UP_FLG = R_TEMP.ADD_UP_FLG THEN

			-- ID
			R_TEMP.ID := DM_MONEY_SCREEN_TEMP.GET_ID;
			-- 入金消込額
			R_TEMP.ADD_UP_AMOUNT := 0;

			-- 各種マスタから名称を翻訳する
			UPDATE_NAMES_FOR_SCR(R_TEMP);

			-- データ追加
			DM_MONEY_SCREEN_TEMP.INSERT_ROW(R_TEMP);

			-- 作成件数カウントアップ
			V_OUTPUT_CNT := V_OUTPUT_CNT + 1;

		END IF;
	END LOOP;

	CLOSE CUR_MONEY_SC;

EXCEPTION
	WHEN OTHERS THEN
		V_MSG		:= '入金一覧照会TEMP構築に失敗しました。';
		CMN_EXCEPTION.RAISE_PROC_ERROR (
				 V_JOB_ID, C_PROGRAM_NAME, C_PACKAGE_NAME
				,C_PROC_NAME, SQLCODE, SQLERRM
				,V_MSG
		);
END CREATE_MONEY_SCREEN_TEMP;

-- *************************************************************************
--	 カーソル定義用動的SQL文字列を組み立てる
-- *************************************************************************
FUNCTION EDIT_SCREEN_SQL
RETURN VARCHAR2
IS
	C_PROC_NAME		CONSTANT	VARCHAR2(30) := 'EDIT_SCREEN_SQL';
	V_MSG						VARCHAR2(4000);

	V_SQL						VARCHAR2(32767);
BEGIN

	V_SQL := 'SELECT';
	V_SQL := V_SQL || ' MONEY_ID';
    V_SQL := V_SQL || ',TOP_DEPT_NO';
    V_SQL := V_SQL || ',MONEY_NO';
    V_SQL := V_SQL || ',UNCONFIRM_INVOICE_TO_FLG';
    V_SQL := V_SQL || ',INVOICE_TO_NO';
    V_SQL := V_SQL || ',INVOICE_TO_ACCOUNT_NO';
    V_SQL := V_SQL || ',INVOICE_TO_ASSUMED_NAME';
    V_SQL := V_SQL || ',DUE_DEPT_NO';
    V_SQL := V_SQL || ',DUE_EMP_CODE';
    V_SQL := V_SQL || ',TRADE_DATE';
    V_SQL := V_SQL || ',DENOMINATION_TYPE';
    V_SQL := V_SQL || ',MONEY_AMOUNT';
    V_SQL := V_SQL || ',ACCOUNT_SUBJECT_CODE';
    V_SQL := V_SQL || ',SUBSIDY_SUBJECT_CODE';
    V_SQL := V_SQL || ',REMARK1';
    V_SQL := V_SQL || ',REMARK2';
    V_SQL := V_SQL || ',MAKE_PAY_REQ_NO';
    V_SQL := V_SQL || ' FROM MONEY';
	-- 最上位部門番号
	V_SQL := V_SQL || ' WHERE TOP_DEPT_NO = ' || CMN_SQL_UTIL.SQ(P_TOP_DEPT_NO);
	-- 開始入金日付、終了入金日付
	V_SQL := V_SQL || ' AND TRADE_DATE >= ' || CMN_SQL_UTIL.V2D(P_MONEY_DATE_S);
	V_SQL := V_SQL || ' AND TRADE_DATE <= ' || CMN_SQL_UTIL.V2D(P_MONEY_DATE_E);
	-- 削除フラグ
	V_SQL := V_SQL || ' AND DELETE_FLG = ' || CMN_SQL_UTIL.SQ(CONST_FLAG.C_FALSE);

	-- 担当部門番号
	IF P_DUE_DEPT_NO IS NOT NULL THEN
		V_SQL := V_SQL || ' AND DUE_DEPT_NO = ' || CMN_SQL_UTIL.SQ(P_DUE_DEPT_NO);
	END IF;
	-- 請求先番号
	IF P_INVOICE_TO_NO IS NOT NULL THEN
		V_SQL := V_SQL || ' AND INVOICE_TO_NO = '
							|| CMN_SQL_UTIL.SQ(P_INVOICE_TO_NO);
	END IF;
	-- 請求先口座番号
	IF P_INVOICE_TO_ACCO_NO IS NOT NULL THEN
		V_SQL := V_SQL || ' AND INVOICE_TO_ACCOUNT_NO = '
							|| CMN_SQL_UTIL.SQ(P_INVOICE_TO_ACCO_NO);
	END IF;
	-- 勘定科目コード
	IF P_ACCOUNT_SUBJECT_CODE IS NOT NULL THEN
		V_SQL := V_SQL || ' AND ACCOUNT_SUBJECT_CODE = '
							|| CMN_SQL_UTIL.SQ(P_ACCOUNT_SUBJECT_CODE);
	END IF;
	-- 金種区分
	IF P_DENOMINATION_TYPE IS NOT NULL THEN
		V_SQL := V_SQL || ' AND DENOMINATION_TYPE = '
			|| CMN_SQL_UTIL.SQ(P_DENOMINATION_TYPE);
	END IF;
	-- 取引先未割付分のみフラグ
	IF P_PARTNER_UNASSIGN_FLG = CONST_FLAG.C_TRUE THEN
		V_SQL := V_SQL || ' AND UNCONFIRM_INVOICE_TO_FLG = '
							|| CMN_SQL_UTIL.SQ(CONST_FLAG.C_TRUE);
	END IF;

	-- 部門未割付分のみフラグ
	IF P_DEPT_UNASSIGN_FLG = CONST_FLAG.C_TRUE THEN
		V_SQL := V_SQL || ' AND UNCONFIRM_DEPT_NO_FLG = '
							|| CMN_SQL_UTIL.SQ(CONST_FLAG.C_TRUE);
	END IF;

	-- 並び順
	V_SQL := V_SQL || ' ORDER BY INVOICE_TO_NO';
	V_SQL := V_SQL || ',INVOICE_TO_ACCOUNT_NO';
	V_SQL := V_SQL || ',TRADE_DATE';
	V_SQL := V_SQL || ',DENOMINATION_TYPE';

	RETURN V_SQL;

EXCEPTION
	WHEN OTHERS THEN
			V_MSG := 'SQLの編集に失敗しました。';
			CMN_EXCEPTION.RAISE_PROC_ERROR (
							 V_JOB_ID, C_PROGRAM_NAME, C_PACKAGE_NAME
							,C_PROC_NAME, SQLCODE, SQLERRM
							,V_MSG
			);
END EDIT_SCREEN_SQL;

-- ****************************************************************************
--	名称翻訳を行う
--	@PARAM	なし
-- ****************************************************************************
PROCEDURE UPDATE_NAMES_FOR_SCR(
	IO_R_TEMP				IN OUT NOCOPY MONEY_SCREEN_TEMP%ROWTYPE
)
IS
	C_PROC_NAME		CONSTANT	VARCHAR2(30)	:= 'UPDATE_NAMES_FOR_SCR';
	V_MSG						VARCHAR2(4000);		-- エラーメッセージ

	R_PARTNER_BASE_MAST		PARTNER_BASE_MAST%ROWTYPE;--取引先マスタ
	R_PARTNER_ACCO_MAST		PARTNER_ACCO_MAST%ROWTYPE;--取引先口座マスタ
	R_DEPT_BASE_MAST		DEPT_BASE_MAST%ROWTYPE;--部門基本マスタ
	R_EMP_BASE_MAST			EMP_BASE_MAST%ROWTYPE;--社員基本マスタ
	R_ACCOUNT_SUBJECT_MAST	ACCOUNT_SUBJECT_MAST%ROWTYPE;--勘定科目マスタ
	R_SUBSIDY_SUBJECT_MAST	SUBSIDY_SUBJECT_MAST%ROWTYPE;--補助勘定科目マスタ
	R_TYPE_MAST				TYPE_MAST%ROWTYPE;--区分マスタ

BEGIN

    IF IO_R_TEMP.INVOICE_TO_NO IS NOT NULL THEN
        -- 請求先名を翻訳する
        DM_PARTNER_BASE_MAST.GET_BY_PK(
                IO_R_TEMP.INVOICE_TO_NO
                ,R_PARTNER_BASE_MAST
        );
        IO_R_TEMP.INVOICE_TO_ABBR := R_PARTNER_BASE_MAST.PARTNER_ABBR;
    
        IF IO_R_TEMP.INVOICE_TO_ACCOUNT_NO IS NOT NULL THEN
            -- 請求先口座名を翻訳する
            DM_PARTNER_ACCO_MAST.GET_BY_LK(
                    IO_R_TEMP.INVOICE_TO_NO
                    ,IO_R_TEMP.INVOICE_TO_ACCOUNT_NO
                    ,R_PARTNER_ACCO_MAST
            );
            IO_R_TEMP.INVOICE_TO_ACCOUNT_NAME := R_PARTNER_ACCO_MAST.PARTNER_ACCO_NAME;
        END IF;
    END IF;

    IF IO_R_TEMP.DUE_DEPT_NO IS NOT NULL THEN
        -- 部門名を翻訳する
        R_DEPT_BASE_MAST := CMN_ORGANIZATION.GET_DEPT_BY_DATE(
                IO_R_TEMP.TRADE_DATE
                ,IO_R_TEMP.DUE_DEPT_NO
        );
        IO_R_TEMP.DUE_DEPT_ABBR := R_DEPT_BASE_MAST.DEPT_ABBR;
    END IF;

    IF IO_R_TEMP.DUE_EMP_CODE IS NOT NULL THEN
        -- 社員名を翻訳する
        DM_EMP_BASE_MAST.GET_BY_PK(
                IO_R_TEMP.DUE_EMP_CODE
                ,R_EMP_BASE_MAST
        );
        IO_R_TEMP.DUE_EMP_NAME := R_EMP_BASE_MAST.EMP_NAME;
    END IF;

    IF IO_R_TEMP.DENOMINATION_TYPE IS NOT NULL THEN
        -- 区分名を翻訳する
        R_TYPE_MAST :=	CMN_TYPE_MAST.GET_TYPE_MAST(
                CONST_CMNNO.C_DENOMINATION_TYPE
                ,IO_R_TEMP.DENOMINATION_TYPE
        );
        IO_R_TEMP.DENOMINATION_ABBR := R_TYPE_MAST.TYPE_ABBR;
    END IF;

    IF IO_R_TEMP.ACCOUNT_SUBJECT_CODE IS NOT NULL THEN
        -- 勘定科目名を翻訳する
        DM_ACCOUNT_SUBJECT_MAST.GET_BY_PK(
                IO_R_TEMP.ACCOUNT_SUBJECT_CODE
                ,R_ACCOUNT_SUBJECT_MAST
        );
        IO_R_TEMP.ACCOUNT_SUBJECT_NAME := R_ACCOUNT_SUBJECT_MAST.ACCOUNT_SUBJECT_NAME;
    
        IF IO_R_TEMP.SUBSIDY_SUBJECT_CODE IS NOT NULL THEN
            -- 補助勘定科目名を翻訳する
            IF R_ACCOUNT_SUBJECT_MAST.SUBSIDY_SUBJECT_CFG_UNIT_TYPE =
                                CONST_PGM_CMN.C_CONFIG_UNIT_TYPE_TOP_DEPT THEN
                DM_SUBSIDY_SUBJECT_MAST.GET_BY_LK(
                        IO_R_TEMP.ACCOUNT_SUBJECT_CODE
                        ,IO_R_TEMP.SUBSIDY_SUBJECT_CODE
                        ,IO_R_TEMP.TOP_DEPT_NO
                        ,R_SUBSIDY_SUBJECT_MAST
                );
            ELSE
                DM_SUBSIDY_SUBJECT_MAST.GET_BY_LK(
                        IO_R_TEMP.ACCOUNT_SUBJECT_CODE
                        ,IO_R_TEMP.SUBSIDY_SUBJECT_CODE
                        ,R_SUBSIDY_SUBJECT_MAST
                );
            END IF;
            IO_R_TEMP.SUBSIDY_SUBJECT_NAME := R_SUBSIDY_SUBJECT_MAST.SUBSIDY_SUBJECT_NAME;
        END IF;
    END IF;

EXCEPTION
	WHEN OTHERS THEN
		V_MSG		:= '名称翻訳に失敗しました。';
		CMN_EXCEPTION.RAISE_PROC_ERROR (
				 V_JOB_ID, C_PROGRAM_NAME, C_PACKAGE_NAME
				,C_PROC_NAME, SQLCODE, SQLERRM
				,V_MSG
		);

END UPDATE_NAMES_FOR_SCR;

-- ****************************************************************************
--	入金差額を取得し、入金差額・入金差額消費税を編集する
--	@PARAM	IO_R_TEMP				入金一覧照会TEMP
--	@RETURN	なし
-- ****************************************************************************
PROCEDURE GET_MONEY_DIFF (
	IO_R_TEMP					IN OUT	MONEY_SCREEN_TEMP%ROWTYPE
	)
IS
	C_PROC_NAME		CONSTANT	VARCHAR2(30)	:= 'GET_MONEY_DIFF';
	V_MSG						VARCHAR2(4000);		-- エラーメッセージ
	V_SQL						VARCHAR2(4000);		-- 動的SQL用

BEGIN

	BEGIN
		-- 入金差額、入金差額消費税を取得する
		V_SQL := ' SELECT NVL(SUM(DECODE(BALANCE_SHEET_TYPE,'
					|| CMN_SQL_UTIL.SQ(CONST_PGM_FINAN.C_BALANCE_SHEET_TYPE_KASI)
					|| ', AMOUNT * (-1), AMOUNT)),0), '
					|| ' NVL(SUM(DECODE(BALANCE_SHEET_TYPE,'
					|| CMN_SQL_UTIL.SQ(CONST_PGM_FINAN.C_BALANCE_SHEET_TYPE_KASI)
					|| ', TAX_AMOUNT * (-1), TAX_AMOUNT)),0)';
		V_SQL := V_SQL	|| ' FROM MONEY_DIFF A';
		V_SQL := V_SQL	|| ' WHERE A.MONEY_ID = '
					|| CMN_SQL_UTIL.SQ(IO_R_TEMP.MONEY_ID);
		EXECUTE IMMEDIATE V_SQL
		INTO  IO_R_TEMP.MONEY_DIFF_AMOUNT, IO_R_TEMP.MONEY_DIFF_TAX_AMOUNT;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			IO_R_TEMP.MONEY_DIFF_AMOUNT := 0;
			IO_R_TEMP.MONEY_DIFF_TAX_AMOUNT := 0;
		WHEN OTHERS THEN
			RAISE EXPECTED_ERROR;
	END;

	BEGIN
		-- 手数料、手数料税額を取得する(検索条件にを追加して取得する)
		V_SQL := V_SQL	|| ' AND MONEY_DIFF_SORT_TYPE = '
						|| CMN_SQL_UTIL.SQ(C_MONEY_DIFF_SORT_TYPE_FEES);
		EXECUTE IMMEDIATE V_SQL
		INTO  IO_R_TEMP.FEES, IO_R_TEMP.FEES_TAX_AMOUNT;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			IO_R_TEMP.FEES := 0;
			IO_R_TEMP.FEES_TAX_AMOUNT := 0;
		WHEN OTHERS THEN
			RAISE EXPECTED_ERROR;
	END;

EXCEPTION
	WHEN EXPECTED_ERROR THEN
		V_MSG := '入金差額索引エラー 入金ID：' || IO_R_TEMP.MONEY_ID;
		CMN_EXCEPTION.RAISE_PROC_ERROR (
				 V_JOB_ID, C_PROGRAM_NAME, C_PACKAGE_NAME
				,C_PROC_NAME, SQLCODE, SQLERRM
				,V_MSG
		);
	WHEN OTHERS THEN
		V_MSG := '入金差額索引エラー 入金ID：' || IO_R_TEMP.MONEY_ID;
		CMN_EXCEPTION.RAISE_PROC_ERROR (
				 V_JOB_ID, C_PROGRAM_NAME, C_PACKAGE_NAME
				,C_PROC_NAME, SQLCODE, SQLERRM
				,V_MSG
		);

END GET_MONEY_DIFF;

-- *****************************************************************************
--  入金消込明細を取得する
--  @PARAM		I_MONEY_ID			入金ID
--  @PARAM		O_FINAN_LINKED_FLG	会計連携済フラグ
-- *****************************************************************************
PROCEDURE GET_MONEY_ADD_UP_DETAIL(
	I_MONEY_ID				IN	MONEY_ADD_UP_DETAIL.MONEY_ID%TYPE
	,O_FINAN_LINKED_FLG		OUT NOCOPY MONEY_ADD_UP_DETAIL.FINAN_LINKED_FLG%TYPE
)
IS

	C_PROC_NAME	CONSTANT		VARCHAR2(30)	:= 'GET_MONEY_ADD_UP_DETAIL';
	V_MSG						VARCHAR2(4000);		-- エラーメッセージ
	V_COUNT					NUMBER := 0;			-- 入金消込関連の件数

BEGIN

	-- 初期化
	O_FINAN_LINKED_FLG := CONST_FLAG.C_FALSE;

	-- 入金消込関連の判定用
	SELECT	COUNT(*)
	INTO 	V_MONEY_ADD_UP_DETAIL_CNT
	FROM	MONEY_ADD_UP_DETAIL
	WHERE	MONEY_ID = I_MONEY_ID;

	SELECT	COUNT(*)
	INTO 	V_COUNT
	FROM	MONEY_ADD_UP_DETAIL
	WHERE	MONEY_ID = I_MONEY_ID
	AND		FINAN_LINKED_FLG = CONST_FLAG.C_TRUE;

	IF V_COUNT > 0 THEN
		-- 取得できた場合、消込済と判定する
		O_FINAN_LINKED_FLG := CONST_FLAG.C_TRUE;
	END IF;

EXCEPTION
	WHEN OTHERS THEN
		-- APPLICATION_ERRORをRAISEする。
		V_MSG := '入金消込明細索引エラー'
					|| ' 入金ID:' || I_MONEY_ID;
		CMN_EXCEPTION.RAISE_PROC_ERROR (
				 V_JOB_ID, C_PROGRAM_NAME, C_PACKAGE_NAME
				,C_PROC_NAME, SQLCODE, SQLERRM
				,V_MSG
		);

END GET_MONEY_ADD_UP_DETAIL;

-- *****************************************************************************
--  入金消込関連を取得し、消込フラグを編集する
--	@PARAM	IO_R_TEMP				入金一覧照会TEMP
-- *****************************************************************************
PROCEDURE EDIT_ADDUP_FLG(
	IO_R_TEMP					IN OUT	MONEY_SCREEN_TEMP%ROWTYPE
)
IS

	C_PROC_NAME	CONSTANT		VARCHAR2(30)	:= 'EDIT_ADDUP_FLG';
	V_MSG						VARCHAR2(4000);		-- エラーメッセージ
	V_SUM_AMOUNT				NUMBER := 0;			-- 集計金額
	V_CNT_MONEY_ADD_UP_REL	NUMBER := 0;			-- 入金消込関連
BEGIN
	-- 入金消込関連の件数をカウントする
	SELECT	COUNT(*)
	INTO 	V_CNT_MONEY_ADD_UP_REL
	FROM	MONEY_ADD_UP_REL
	WHERE	MONEY_ID = IO_R_TEMP.MONEY_ID;

	IF V_CNT_MONEY_ADD_UP_REL > 0 THEN

		SELECT	NVL(SUM(ADD_UP_AMOUNT),0)
		INTO 	V_SUM_AMOUNT
		FROM	MONEY_ADD_UP_REL
		WHERE	MONEY_ID = IO_R_TEMP.MONEY_ID;
	
		IO_R_TEMP.ADD_UP_FLG := CONST_FLAG.C_FALSE;
		IF (IO_R_TEMP.MONEY_AMOUNT
			+ IO_R_TEMP.MONEY_DIFF_AMOUNT + IO_R_TEMP.MONEY_DIFF_TAX_AMOUNT
			- V_SUM_AMOUNT) = 0 THEN
			IO_R_TEMP.ADD_UP_FLG := CONST_FLAG.C_TRUE;
		END IF;
	
	ELSE
		IF V_MONEY_ADD_UP_DETAIL_CNT > 0 THEN
			IO_R_TEMP.ADD_UP_FLG := CONST_FLAG.C_TRUE;
		ElSE
			IO_R_TEMP.ADD_UP_FLG := CONST_FLAG.C_FALSE;
		END IF;
	END IF;

EXCEPTION
	WHEN OTHERS THEN
		-- APPLICATION_ERRORをRAISEする。
		V_MSG := '入金消込関連索引エラー'
					|| ' 入金ID:' || IO_R_TEMP.MONEY_ID;
		CMN_EXCEPTION.RAISE_PROC_ERROR (
				 V_JOB_ID, C_PROGRAM_NAME, C_PACKAGE_NAME
				,C_PROC_NAME, SQLCODE, SQLERRM
				,V_MSG
		);

END EDIT_ADDUP_FLG;

END "CMN_CREATE_MONEY_SCREEN_TEMP";
