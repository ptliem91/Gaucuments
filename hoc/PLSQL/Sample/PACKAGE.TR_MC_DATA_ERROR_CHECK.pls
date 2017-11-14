CREATE OR REPLACE PACKAGE "TR_MC_DATA_ERROR_CHECK" AS
-- *****************************************************************************
--		$Id: PACKAGE.TR_MC_DATA_ERROR_CHECK.pls 11077 2013-08-19 07:11:45Z hungmh $
--		顧客名				：三谷産業株式会社
--		システム名			：Ｌ２プロジェクト
--		サブシステム名			：190 生産管理
--		業種名（事業部名）	    ：物販型　グループ会社
--		All rights reserved, Copyright (c) MITANI SANGYO Co.,Ltd. 2008-
-- *****************************************************************************

	-- 190_20_10_02 原材料発注残エラーチェック
	FUNCTION CHECK_ORDER_REMAIN(
		I_JOB_ID					IN	NUMBER
		,I_EXEC_JOB_ID				IN	VARCHAR2
		,I_TOP_DEPT_NO				IN	VARCHAR2
	) RETURN NUMBER;

    -- 190_20_11_02 仕入実績データエラーチェック
    FUNCTION CHECK_PURCHASE_ACTUAL(
        I_JOB_ID                    IN NUMBER      --ジョブＩＤ
        ,I_EXEC_JOB_ID              IN VARCHAR2    --実行ユーザーＩＤ
        ,I_TOP_DEPT_NO              IN VARCHAR2    --最上位部門番号
    )RETURN NUMBER;

    -- 190_20_12_02 原材料経費払出データエラーチェック
    FUNCTION CHECK_MATERIAL_TAKE_OUT(
        I_JOB_ID                    IN NUMBER      --ジョブＩＤ
        ,I_EXEC_JOB_ID              IN VARCHAR2    --実行ユーザーＩＤ
        ,I_TOP_DEPT_NO              IN VARCHAR2    --最上位部門番号
    )RETURN NUMBER;

    -- 190_20_13_02 在庫残高データエラーチェック
    FUNCTION CHECK_INVENT_BALANCE_AMO(
        I_JOB_ID                    IN NUMBER      --ジョブＩＤ
        ,I_EXEC_JOB_ID              IN VARCHAR2    --実行ユーザーＩＤ
        ,I_TOP_DEPT_NO              IN VARCHAR2    --最上位部門番号
    )RETURN NUMBER;

    -- 190_20_14_02 製品出荷データエラーチェック
    FUNCTION CHECK_GOODS_OUT_GO(
        I_JOB_ID                    IN NUMBER      --ジョブＩＤ
        ,I_EXEC_JOB_ID              IN VARCHAR2    --実行ユーザーＩＤ
        ,I_TOP_DEPT_NO              IN VARCHAR2    --最上位部門番号
    )RETURN NUMBER;

    -- 190_20_16_02 製造原価データエラーチェック
    FUNCTION CHECK_PROD_COST(
        I_JOB_ID                    IN NUMBER      --ジョブＩＤ
        ,I_EXEC_JOB_ID              IN VARCHAR2    --実行ユーザーＩＤ
        ,I_TOP_DEPT_NO              IN VARCHAR2    --最上位部門番号
    )RETURN NUMBER;

    -- 190_20_17_02 商品マスタデータエラーチェック
    FUNCTION CHECK_GOODS_MAST(
        I_JOB_ID                    IN NUMBER      --ジョブＩＤ
        ,I_EXEC_JOB_ID              IN VARCHAR2    --実行ユーザーＩＤ
        ,I_TOP_DEPT_NO              IN VARCHAR2    --最上位部門番号
    )RETURN NUMBER;

	-- 190_20_19_02   仕掛原価データエラーチェック
	FUNCTION CHECK_IN_PROCESS_COST(
        I_JOB_ID                    IN NUMBER      --ジョブＩＤ
        ,I_EXEC_JOB_ID              IN VARCHAR2    --実行ユーザーＩＤ
        ,I_TOP_DEPT_NO              IN VARCHAR2    --最上位部門番号
	)RETURN NUMBER;
	
	-- 190_20_21_02   製品在庫表原価実績データエラーチェック
	FUNCTION CHECK_IN_PROCESS_COST_ACT(
        I_JOB_ID                    IN NUMBER      --ジョブＩＤ
        ,I_EXEC_JOB_ID              IN VARCHAR2    --実行ユーザーＩＤ
        ,I_TOP_DEPT_NO              IN VARCHAR2    --最上位部門番号
	)RETURN NUMBER;

END "TR_MC_DATA_ERROR_CHECK";
