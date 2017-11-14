CREATE OR REPLACE PACKAGE BODY "TR_MC_DATA_ERROR_CHECK" AS
-- *****************************************************************************
--		$Id: PACKAGE.BODY.TR_MC_DATA_ERROR_CHECK.pls 11120 2013-08-30 02:19:08Z trangnt $
--		顧客名				：三谷産業株式会社
--		システム名			：Ｌ２プロジェクト
--		サブシステム名			：190 生産管理
--		業種名（事業部名）	    ：物販型　グループ会社
--		All rights reserved, Copyright (c) MITANI SANGYO Co.,Ltd. 2008-
-- *****************************************************************************

	-- パッケージ名等
	C_PROGRAM_NAME	CONSTANT	VARCHAR2(100)	:= '生産管理データエラーチェック';
	C_PACKAGE_NAME	CONSTANT	VARCHAR2(30)	:= 'TR_MC_DATA_ERROR_CHECK';

	LOGICAL_ERROR	EXCEPTION;              -- 論理エラー
	EXPECTED_ERROR	EXCEPTION;              -- 予期したエラー

	P_TOP_DEPT_NO				 VARCHAR2(20);		-- 1.最上位部門番号（必須）

	-- 定数
	-- その他広域変数
	V_JOB_ID                    NUMBER := NULL;         -- ジョブID
	V_WARN_CNT		            NUMBER := 0;            -- 警告発生件数
	V_END_CODE                  NUMBER;                 -- 終了コード

	-- システム日付退避
    V_SYSDATE					DATE;

-- *****************************************************************************
--    サブプログラム宣言
-- *****************************************************************************
-- 取引先基本マスタ索引
FUNCTION GET_PARTNER(
	I_COUNT						IN	NUMBER
	,I_PARTNER_NO				IN	PARTNER_BASE_MAST.PARTNER_NO%TYPE
) RETURN NUMBER;

-- V部門基本マスタを索引する。
FUNCTION GET_V_DEPT_BASE_MAST(
    I_COUNT                     IN	    NUMBER
    ,I_DEPT_NO                  IN      V_DEPT_BASE_MAST.DEPT_NO%TYPE
    ,I_PARAM_NAME               IN      VARCHAR2
) RETURN NUMBER;

-- 社員基本マスタを索引する。
FUNCTION GET_EMP_BASE_MAST(
    I_COUNT                  IN NUMBER
    ,I_EMP_CODE              IN EMP_BASE_MAST.EMP_CODE%TYPE
)RETURN NUMBER;

--取引先属性（仕入先・諸掛先）索引する。
PROCEDURE GET_PARTNER_ATTRIBUTE_MAST(
	 I_COUNT					IN	NUMBER
	,I_PARTNER_NO				IN	PARTNER_ATTRIBUTE_MAST.PARTNER_NO%TYPE
    ,I_PARTNER_ACCOUNT_NO       IN  PARTNER_ATTRIBUTE_MAST.PARTNER_ACCOUNT_NO%TYPE
	,O_R_PARTNER_ATTRIBUTE_MAST	OUT NOCOPY	PARTNER_ATTRIBUTE_MAST%ROWTYPE
);

--取引先属性（支払先）索引する。
FUNCTION GET_PAY_TO(
	I_COUNT						IN	NUMBER
	,I_PARTNER_NO				IN	PARTNER_ATTRIBUTE_MAST.PARTNER_NO%TYPE
    ,I_PARTNER_ACCOUNT_NO       IN  PARTNER_ATTRIBUTE_MAST.PARTNER_ACCOUNT_NO%TYPE
) RETURN NUMBER;

--ＥＤＩコード区分変換(商社)を索引する。
FUNCTION GET_EDI_CODE_TYPE_CONV(
    I_COUNT                     IN NUMBER
    ,I_TOP_DEPT_NO              IN TR_EDI_CODE_TYPE_CONV.TOP_DEPT_NO%TYPE
    ,I_EDI_DISTINCTION_TYPE     IN TR_EDI_CODE_TYPE_CONV.EDI_DISTINCTION_TYPE%TYPE
    ,I_COMMON_NO                IN TR_EDI_CODE_TYPE_CONV.COMMON_NO%TYPE
    ,I_CODE_TYPE_NO             IN TR_EDI_CODE_TYPE_CONV.CODE_TYPE_NO%TYPE
    ,I_OPER_START_DATE          IN TR_EDI_CODE_TYPE_CONV.OPER_START_DATE%TYPE
    ,I_PARAM_NAME               IN VARCHAR2
)RETURN TR_EDI_CODE_TYPE_CONV%ROWTYPE;

-- 会計年月チェック
PROCEDURE CHECK_FINAN_YM(
    I_COUNT         IN               NUMBER
    ,I_FINAN_YM     IN               VARCHAR2
    ,I_CHECKED_YM   IN               VARCHAR2
    ,I_PARAM_NAME   IN               VARCHAR2
    ,I_O_ERR_FLG    IN OUT NOCOPY   VARCHAR2
);

-- 在庫種類区分チェック
PROCEDURE CHECK_INVENT_KIND_TYPE(
    I_COUNT                 IN                  NUMBER
    ,I_INVENT_KIND_TYPE     IN                  VARCHAR2
    ,I_O_ERR_FLG            IN OUT NOCOPY      VARCHAR2
);

-- 在庫仕訳種別チェック
PROCEDURE CHECK_INVENT_JNL_KIND_TYPE(
    I_COUNT                 IN                   NUMBER
    ,I_JNL_INVENT_KIND_TYPE IN                   VARCHAR2
    ,I_O_ERR_FLG            IN OUT NOCOPY       VARCHAR2
);

-- 商品マスタを索引
FUNCTION GET_GOODS_MAST(
    I_COUNT                 IN              NUMBER
    ,I_GOODS_CODE           IN              VARCHAR2
)RETURN NUMBER;

--倉庫マスタを索引
FUNCTION GET_WAREHOUSE(
    I_COUNT                 IN              NUMBER
    ,I_TOP_DEPT_NO          IN              VARCHAR2
    ,I_WAREHOUSE_NO         IN              VARCHAR2
    ,I_PLACE_CODE           IN              VARCHAR2
    ,I_PARAM_NAME           IN              VARCHAR2
)RETURN NUMBER;

--在庫置場マスタを索引
FUNCTION GET_INVENT_PLACE(
    I_COUNT                 IN              NUMBER
    ,I_TOP_DEPT_NO          IN              VARCHAR2
    ,I_WAREHOUSE_NO         IN              VARCHAR2
    ,I_INVENT_PLACE_NO      IN              VARCHAR2
    ,I_PLACE_CODE           IN              VARCHAR2
    ,I_PARAM_NAME           IN              VARCHAR2
)RETURN NUMBER;

-- 年度チェック
PROCEDURE CHECK_FINAN_YEAR(
    I_COUNT                 IN                  VARCHAR2
    ,I_FINAN_YEAR           IN                  VARCHAR2
    ,I_CHECKED_FINAN_YEAR   IN                  VARCHAR2
    ,I_O_ERR_FLG            IN OUT NOCOPY      VARCHAR2
);
-- 在庫計算方法区分チェック
PROCEDURE CHECK_INVENT_CALC_TYPE(
    I_COUNT                 IN                  VARCHAR2
    ,I_INVENT_CALC_TYPE     IN                  VARCHAR2
    ,I_O_ERR_FLG            IN OUT NOCOPY      VARCHAR2
);

-- *****************************************************************************
--    メイン処理
-- *****************************************************************************
-- *****************************************************************************
--  プログラム名：190_20_10_02 原材料発注残エラーチェック
--  １．原材料発注残の内容をチェックする。
--
--  @PARAM		I_JOB_ID			ジョブID
--  @PARAM		I_EXEC_JOB_ID		実行ユーザID
--  @PARAM		I_TOP_DEPT_NO		最上位部門番号
--  @RETURN		終了コード
-- *****************************************************************************
FUNCTION CHECK_ORDER_REMAIN(
    I_JOB_ID					IN	NUMBER
	,I_EXEC_JOB_ID				IN	VARCHAR2
	,I_TOP_DEPT_NO				IN	VARCHAR2
) RETURN NUMBER
IS
	C_PROC_NAME		CONSTANT	VARCHAR2(30)
								:= 'CHECK_ORDER_REMAIN';
	-- ログ出力用名称
	C_INFOLOG_NAME	CONSTANT	VARCHAR2(30)
								:= '原材料発注残エラーチェック';

	V_ERR_MSG					VARCHAR2(4000); -- エラーメッセージ

    -- 処理カウント
    V_IN_COUNT                  NUMBER;         --読込件数
    V_ERR_COUNT                 NUMBER;       	--エラー件数

	-- 原材料発注残を取得する
	CURSOR CUR_MATERIAL_ORDER_REMAIN IS
		SELECT	    A.*
		FROM	    TR_MATERIAL_ORDER_REMAIN A
		WHERE	    A.TOP_DEPT_NO = P_TOP_DEPT_NO
		ORDER BY	A.TR_MATERIAL_ORDER_REMAIN_ID
		FOR UPDATE;

BEGIN

	-- 初期化
	V_END_CODE := CONST_BATCH_EXIT_CODE.C_NORMAL_EXIT;
	V_WARN_CNT := 0;			-- 警告発生件数

	--引数
	P_TOP_DEPT_NO := I_TOP_DEPT_NO;

	-- ジョブIDを取得
	V_JOB_ID := CMN.PRE_PROCESS(I_JOB_ID, I_EXEC_JOB_ID, C_PACKAGE_NAME);

	-- プログラム開始情報をログに出力
	CMN.INFO(V_JOB_ID
			,C_PACKAGE_NAME
			,C_INFOLOG_NAME || 'を開始しました。');

    -- システム日付を取得
	V_SYSDATE := SYSDATE;

    -- カウントゼロクリア
    V_IN_COUNT := 0;
    V_ERR_COUNT := 0;

	-- 本処理

	FOR R_MATERIAL_ORDER_REMAIN IN CUR_MATERIAL_ORDER_REMAIN LOOP

        -- 読込件数カウントアップ
        V_IN_COUNT := V_IN_COUNT + 1;

		-- 仕入先チェック
		IF	GET_PARTNER(V_IN_COUNT,R_MATERIAL_ORDER_REMAIN.SUPPLIER_NO) = 0 THEN
			--索引不可時
			V_ERR_COUNT := V_ERR_COUNT + 1;

			-- 更新
			UPDATE  TR_MATERIAL_ORDER_REMAIN
			SET     ERROR_FLG       = CONST_FLAG.C_TRUE
				    ,REG_DATE_TIME  = V_SYSDATE
			WHERE CURRENT OF CUR_MATERIAL_ORDER_REMAIN;
    	ELSE
			-- 更新
			UPDATE  TR_MATERIAL_ORDER_REMAIN
			SET     ERROR_FLG       = CONST_FLAG.C_FALSE
				    ,REG_DATE_TIME  = V_SYSDATE
			WHERE CURRENT OF CUR_MATERIAL_ORDER_REMAIN;
		END IF;

    END LOOP;

	-- コミットする
	COMMIT;

	-- 件数ログ表示
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '原材料発注残　　　　　　読込件数: ' ||
        TO_CHAR(V_IN_COUNT,  '999,999')     || ' 件');
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '原材料発注残　　　　　エラー件数: ' ||
        TO_CHAR(V_ERR_COUNT,  '999,999')    || ' 件');

	-- 正常終了情報をログに出力
	IF V_ERR_COUNT = 0 THEN
		CMN.INFO(V_JOB_ID
				,C_PACKAGE_NAME
				,C_INFOLOG_NAME || 'が正常終了しました。');
	ELSE
		V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		-- プログラム異常終了情報をログに出力
		V_ERR_MSG := '原材料発注残エラーチェックにてエラーが発生しています。';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						NULL, NULL, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
	END IF;

	-- 後処理
	CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);

    RETURN V_END_CODE;

EXCEPTION
	WHEN OTHERS THEN
		-- ロールバック
		ROLLBACK;
		-- 異常終了コードをセット
		V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		-- プログラム異常終了情報をログに出力
		V_ERR_MSG := '予期せぬエラーが発生しました。';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						SQLCODE, SQLERRM, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
END CHECK_ORDER_REMAIN;

-- *****************************************************************************
--　プログラム名 : 190_20_11_02 仕入実績データエラーチェック
--  @PARAM		I_JOB_ID			ジョブID
--  @PARAM		I_EXEC_JOB_ID		実行ユーザID
--  @PARAM		I_TOP_DEPT_NO		最上位部門番号
--  @RETURN		終了コード
-- *****************************************************************************
FUNCTION CHECK_PURCHASE_ACTUAL(
    I_JOB_ID                IN NUMBER      --ジョブＩＤ
    ,I_EXEC_JOB_ID          IN VARCHAR2    --実行ユーザーＩＤ
    ,I_TOP_DEPT_NO          IN VARCHAR2    --最上位部門番号
)RETURN NUMBER
IS

    C_PROC_NAME		CONSTANT	VARCHAR2(30)
								:= 'CHECK_PURCHASE_ACTUAL';
	-- ログ出力用名称
	C_INFOLOG_NAME	CONSTANT	VARCHAR2(30)
								:= '仕入実績データエラーチェック';

	V_MSG						            VARCHAR2(4000); -- メッセージ
	V_ERR_MSG					            VARCHAR2(4000); -- エラーメッセージ
    V_FINAN_YM                              VARCHAR2(6); -- 会計年月
    R_EDI_CODE_TYPE_CONV_UNIT               TR_EDI_CODE_TYPE_CONV%ROWTYPE; --ＥＤＩコード区分変換(商社) UNIT TYPE
    R_EDI_CODE_TYPE_CONV_CONSU_TAX          TR_EDI_CODE_TYPE_CONV%ROWTYPE; --ＥＤＩコード区分変換(商社) CONSU TAX TAXATION TYPE
    R_EDI_CODE_TYPE_CONV_TAX_RATE           TR_EDI_CODE_TYPE_CONV%ROWTYPE; --ＥＤＩコード区分変換(商社) TAX RATE TYPE
    R_TYPE_MAST                             TYPE_MAST%ROWTYPE; --系統マスタを取得
    V_PARAM_NAME                            VARCHAR2(50); -- USE FOR PARAM NAME IN STEP 6, 7, 8

	--取引先属性マスタ（支払先属性マスタ取得のために使用）
	R_PARTNER_ATTRIBUTE_MAST				PARTNER_ATTRIBUTE_MAST%ROWTYPE;

    -- 処理カウント
    V_IN_COUNT                  NUMBER;         --読込件数
    V_ERR_COUNT                 NUMBER;       	--エラー件数
    V_ERR_FLG                   VARCHAR2(1);    --エラーフラグ

	-- 抽出対象となる仕入実績ワークを取得する
	CURSOR CUR_TR_PURCHASE_ACT_WK IS
		SELECT      A.*
		FROM	    TR_PURCHASE_ACT_WK A
		WHERE	    A.TOP_DEPT_NO = P_TOP_DEPT_NO
		ORDER BY	A.ID
		FOR UPDATE;

BEGIN

	-- 初期化
	V_END_CODE := CONST_BATCH_EXIT_CODE.C_NORMAL_EXIT;
	V_WARN_CNT := 0;			-- 警告発生件数

	--引数
	P_TOP_DEPT_NO := I_TOP_DEPT_NO;

	-- (1) ジョブIDを取得
	V_JOB_ID := CMN.PRE_PROCESS(I_JOB_ID, I_EXEC_JOB_ID, C_PACKAGE_NAME);

	-- (2) プログラム開始情報をログに出力
	CMN.INFO(V_JOB_ID
			,C_PACKAGE_NAME
			,C_INFOLOG_NAME || 'を開始しました。');

    --（３）会計年月を取得する。
    V_FINAN_YM := CMN_OPER_ADMIN.GET_TOP_DEPT_FINAN_YM(P_TOP_DEPT_NO);

    -- システム日付を取得
	V_SYSDATE := SYSDATE;

    -- カウントゼロクリア
    V_IN_COUNT := 0;
    V_ERR_COUNT := 0;

	-- 本処理

	FOR R_PURCHASE_ACT_WK IN CUR_TR_PURCHASE_ACT_WK LOOP

        -- 読込件数カウントアップ
        V_IN_COUNT := V_IN_COUNT + 1;

        -- ① エラーフラグ
        V_ERR_FLG := CONST_FLAG.C_FALSE;

        -- ② 部門存在チェック
		IF	GET_V_DEPT_BASE_MAST(V_IN_COUNT, R_PURCHASE_ACT_WK.PURCHASE_DUE_DEPT_NO, '仕入担当部門番号') = 0 THEN
            -- エラーフラグ
            V_ERR_FLG := CONST_FLAG.C_TRUE;
		END IF;

        -- ③ 部門番号チェック
        IF SUBSTR(R_PURCHASE_ACT_WK.PURCHASE_DUE_DEPT_NO, 0, 3)
            <> SUBSTR(P_TOP_DEPT_NO, 0, 3) THEN
            -- エラーフラグ
            V_ERR_FLG := CONST_FLAG.C_TRUE;
            V_MSG := '部門番号（先頭３ケタ）アンマッチエラー。'                 ||
            ' レコード番号＝['      || V_IN_COUNT                               || ']' ||
            ' 最上位部門番号＝['    || P_TOP_DEPT_NO                            || ']' ||
            ' 仕入担当部門番号＝['  || R_PURCHASE_ACT_WK.PURCHASE_DUE_DEPT_NO   || ']';
            CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
        END IF;

        -- ④ 社員存在チェック
        IF R_PURCHASE_ACT_WK.PURCHASE_DUE_EMP_CODE IS NOT NULL THEN
            IF GET_EMP_BASE_MAST(V_IN_COUNT, R_PURCHASE_ACT_WK.PURCHASE_DUE_EMP_CODE) = 0 THEN
                -- エラーフラグ
                V_ERR_FLG := CONST_FLAG.C_TRUE;
            END IF;
        END IF;

		-- ⑤-0
		--仕入先・諸掛先属性情報を取得する
		R_PARTNER_ATTRIBUTE_MAST := NULL;
		GET_PARTNER_ATTRIBUTE_MAST(
			V_IN_COUNT,
			R_PURCHASE_ACT_WK.SUPPLIER_NO,
			R_PURCHASE_ACT_WK.SUPPLIER_ACCOUNT_NO,
			R_PARTNER_ATTRIBUTE_MAST);
		IF	R_PARTNER_ATTRIBUTE_MAST.PARTNER_ATTRIBUTE_ID IS NULL	THEN
            -- エラーフラグ
            V_ERR_FLG := CONST_FLAG.C_TRUE;
		END IF;


        -- ⑤ 仕入先存在チェック
        IF GET_PAY_TO(V_IN_COUNT, R_PARTNER_ATTRIBUTE_MAST.INVO_PAY_TO_PARTNER_NO,
                        R_PARTNER_ATTRIBUTE_MAST.INVO_PAY_TO_PARTNER_ACCOUNT_NO) = 0 THEN
            -- エラーフラグ
            V_ERR_FLG := CONST_FLAG.C_TRUE;
        END IF;

        -- ⑥ ＭＣ基準単位ＣＤチェック
        R_EDI_CODE_TYPE_CONV_UNIT := NULL;
        V_PARAM_NAME := 'ＭＣ基準単位ＣＤ';

        BEGIN
            R_EDI_CODE_TYPE_CONV_UNIT := GET_EDI_CODE_TYPE_CONV(
                                    V_IN_COUNT, P_TOP_DEPT_NO,
                                    CONST_TR_PGM_SALES.C_EDI_DISTINCTION_TYPE_MC,
                                    CONST_CMNNO.C_UNIT_TYPE,
                                    R_PURCHASE_ACT_WK.MC_UNIT_CD,
                                    R_PURCHASE_ACT_WK.PURCHASE_DATE,
                                    V_PARAM_NAME);
        EXCEPTION
            WHEN OTHERS THEN
                -- エラーフラグ
                V_ERR_FLG := CONST_FLAG.C_TRUE;

        END;
        --区分マスタ情報を索引する。
        IF R_EDI_CODE_TYPE_CONV_UNIT.TR_EDI_CODE_TYPE_CONV_ID IS NOT NULL THEN
            BEGIN
                R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(
                            CONST_CMNNO.C_UNIT_TYPE,
                            R_EDI_CODE_TYPE_CONV_UNIT.CHAR_HEAD1);
            EXCEPTION
                WHEN OTHERS THEN
                    -- エラーフラグ
                    V_ERR_FLG := CONST_FLAG.C_TRUE;

                    V_MSG := '区分マスタ索引エラー。'                               ||
                    ' レコード番号＝['      || V_IN_COUNT                           || ']' ||
                    ' ＭＣ基準単位ＣＤ＝['  || R_PURCHASE_ACT_WK.MC_UNIT_CD         || ']' ||
                    ' 仕入単位区分＝['      || R_EDI_CODE_TYPE_CONV_UNIT.CHAR_HEAD1 || ']';
                    CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
            END;
        END IF;
        -- ⑦ ＭＣ税ＣＤチェック
        R_EDI_CODE_TYPE_CONV_CONSU_TAX := NULL;
        V_PARAM_NAME := 'ＭＣ税ＣＤ';
        BEGIN
            R_EDI_CODE_TYPE_CONV_CONSU_TAX := GET_EDI_CODE_TYPE_CONV(
                                            V_IN_COUNT, P_TOP_DEPT_NO,
                                            CONST_TR_PGM_SALES.C_EDI_DISTINCTION_TYPE_MC,
                                            CONST_CMNNO.C_CONSU_TAX_TAXATION_TYPE,
                                            R_PURCHASE_ACT_WK.MC_CTAX_CD,
                                            R_PURCHASE_ACT_WK.PURCHASE_DATE,
                                            V_PARAM_NAME);
        EXCEPTION
            WHEN OTHERS THEN
                -- エラーフラグ
                V_ERR_FLG := CONST_FLAG.C_TRUE;
        END;

        --区分マスタ情報を索引する。
        IF R_EDI_CODE_TYPE_CONV_CONSU_TAX.TR_EDI_CODE_TYPE_CONV_ID IS NOT NULL THEN
            BEGIN
                R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(
                            CONST_CMNNO.C_CONSU_TAX_TAXATION_TYPE,
                            R_EDI_CODE_TYPE_CONV_CONSU_TAX.CHAR_HEAD1);
            EXCEPTION
                WHEN OTHERS THEN
                    -- エラーフラグ
                    V_ERR_FLG := CONST_FLAG.C_TRUE;

                    V_MSG := '区分マスタ索引エラー。'                                          ||
                    ' レコード番号＝['      || V_IN_COUNT                                      || ']' ||
                    ' ＭＣ税ＣＤ＝['        || R_PURCHASE_ACT_WK.MC_CTAX_CD                    || ']' ||
                    ' 消費税課税区分＝['    || R_EDI_CODE_TYPE_CONV_CONSU_TAX.CHAR_HEAD1       || ']';
                    CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
            END;
        END IF;

        -- ⑧ ＭＣ消費税率チェック
        R_EDI_CODE_TYPE_CONV_TAX_RATE := NULL;
        V_PARAM_NAME := 'ＭＣ消費税率';
        BEGIN
            R_EDI_CODE_TYPE_CONV_TAX_RATE := GET_EDI_CODE_TYPE_CONV(
                                            V_IN_COUNT, P_TOP_DEPT_NO,
                                            CONST_TR_PGM_SALES.C_EDI_DISTINCTION_TYPE_MC,
                                            CONST_CMNNO.C_TAX_RATE_TYPE,
                                            R_PURCHASE_ACT_WK.MC_CTAX_RATE,
                                            R_PURCHASE_ACT_WK.PURCHASE_DATE,
                                            V_PARAM_NAME);
            EXCEPTION
                WHEN OTHERS THEN
                   -- エラーフラグ
                    V_ERR_FLG := CONST_FLAG.C_TRUE;
        END;

        --区分マスタ情報を索引する。
        IF R_EDI_CODE_TYPE_CONV_TAX_RATE.TR_EDI_CODE_TYPE_CONV_ID IS NOT NULL THEN
            BEGIN
                R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(
                            CONST_CMNNO.C_TAX_RATE_TYPE,
                            R_EDI_CODE_TYPE_CONV_TAX_RATE.CHAR_HEAD1);
            EXCEPTION
                WHEN OTHERS THEN
                -- エラーフラグ
                V_ERR_FLG := CONST_FLAG.C_TRUE;

                V_MSG := '区分マスタ索引エラー。'                                  ||
                ' レコード番号＝['  || V_IN_COUNT                                  || ']' ||
                ' ＭＣ消費税率＝['  || R_PURCHASE_ACT_WK.MC_CTAX_RATE              || ']' ||
                ' 税率区分＝['      || R_EDI_CODE_TYPE_CONV_TAX_RATE.CHAR_HEAD1    || ']';
                CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
            END;
        END IF;

        -- ⑨ 会計年月チェック
        CHECK_FINAN_YM(V_IN_COUNT, V_FINAN_YM, R_PURCHASE_ACT_WK.FINAN_YM, 'ＭＣ会計年月', V_ERR_FLG);

        -- ⑩ 在庫種類区分チェック
        CHECK_INVENT_KIND_TYPE(V_IN_COUNT, R_PURCHASE_ACT_WK.INVENT_KIND_TYPE, V_ERR_FLG);

        -- ⑪ 赤黒区分チェック
        BEGIN
            R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(
                        CONST_CMNNO.C_RED_BLACK_TYPE,
                        R_PURCHASE_ACT_WK.RED_BLACK_TYPE);
            EXCEPTION
                WHEN OTHERS THEN
                    -- エラーフラグ
                    V_ERR_FLG := CONST_FLAG.C_TRUE;
                    V_MSG := '区分マスタ索引エラー。'                       ||
                    ' レコード番号＝['  || V_IN_COUNT                       || ']' ||
                    ' 赤黒区分＝['      || R_PURCHASE_ACT_WK.RED_BLACK_TYPE || ']';
                    CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
        END;

        -- （４）チェック判定を行う。
        IF V_ERR_FLG = CONST_FLAG.C_TRUE THEN
            V_ERR_COUNT := V_ERR_COUNT + 1;
        END IF;
        IF V_ERR_COUNT = 0 THEN
            UPDATE  TR_PURCHASE_ACT_WK
			SET     PURCHASE_UNIT_TYPE          = R_EDI_CODE_TYPE_CONV_UNIT.CHAR_HEAD1
                    ,CONSU_TAX_TAXATION_TYPE    = R_EDI_CODE_TYPE_CONV_CONSU_TAX.CHAR_HEAD1
                    ,TAX_RATE_TYPE              = R_EDI_CODE_TYPE_CONV_TAX_RATE.CHAR_HEAD1
				    ,REG_DATE_TIME              = V_SYSDATE
			WHERE CURRENT OF CUR_TR_PURCHASE_ACT_WK;
        END IF;
    END LOOP;

	-- 件数ログ表示
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '仕入実績ワーク　　　　　　読込件数: ' ||
        TO_CHAR(V_IN_COUNT,  '999,999')     || ' 件');
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '仕入実績ワーク　　　　　エラー件数: ' ||
        TO_CHAR(V_ERR_COUNT,  '999,999')    || ' 件');

	-- 正常終了情報をログに出力
	IF V_ERR_COUNT = 0 THEN
        -- コミットする
    	COMMIT;
		CMN.INFO(V_JOB_ID
				,C_PACKAGE_NAME
				,C_INFOLOG_NAME || 'が正常終了しました。');
	ELSE
        -- ロールバック
        ROLLBACK;
		-- プログラム異常終了情報をログに出力
		V_ERR_MSG := '仕入実績データエラーチェックにてエラーが発生しています。';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						NULL, NULL, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
	END IF;

	-- 後処理
	CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);

    RETURN V_END_CODE;

EXCEPTION
	WHEN OTHERS THEN
		-- ロールバック
		ROLLBACK;
		-- 異常終了コードをセット
		V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		-- プログラム異常終了情報をログに出力
		V_ERR_MSG := '予期せぬエラーが発生しました。';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						SQLCODE, SQLERRM, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
END CHECK_PURCHASE_ACTUAL;

-- *****************************************************************************
--　プログラム名 : 190_20_12_02 原材料経費払出データエラーチェック
--  @PARAM		I_JOB_ID			ジョブID
--  @PARAM		I_EXEC_JOB_ID		実行ユーザID
--  @PARAM		I_TOP_DEPT_NO		最上位部門番号
--  @RETURN		終了コード
-- *****************************************************************************
FUNCTION CHECK_MATERIAL_TAKE_OUT(
    I_JOB_ID                    IN NUMBER      --ジョブＩＤ
    ,I_EXEC_JOB_ID              IN VARCHAR2    --実行ユーザーＩＤ
    ,I_TOP_DEPT_NO              IN VARCHAR2    --最上位部門番号
)RETURN NUMBER
IS
    C_PROC_NAME		CONSTANT	VARCHAR2(30)
								:= 'CHECK_MATERIAL_TAKE_OUT';
	-- ログ出力用名称
	C_INFOLOG_NAME	CONSTANT	VARCHAR2(50)
								:= '原材料経費払出データエラーチェック';

	V_MSG						VARCHAR2(4000); -- メッセージ
	V_ERR_MSG					VARCHAR2(4000); -- エラーメッセージ

    -- 処理カウント
    V_IN_COUNT                  NUMBER;         --読込件数
    V_ERR_COUNT                 NUMBER;       	--エラー件数
    V_ERR_FLG                   VARCHAR2(1);    --エラーフラグ

    V_FINAN_YM                  VARCHAR(6);     --会計年月
    R_EDI_CODE_TYPE_CONV        TR_EDI_CODE_TYPE_CONV%ROWTYPE; --ＥＤＩコード区分変換(商社)
    R_TYPE_MAST                 TYPE_MAST%ROWTYPE; --区分マスタ情報

	-- 抽出対象となる原材料経費払出ワークを取得する
	CURSOR CUR_MATERIAL_WK IS
        SELECT      A.*
        FROM        TR_MATERIAL_WK A
        WHERE       A.TOP_DEPT_NO = P_TOP_DEPT_NO
        ORDER BY    A.ID
        FOR UPDATE;

BEGIN

	-- 初期化
	V_END_CODE := CONST_BATCH_EXIT_CODE.C_NORMAL_EXIT;
	V_WARN_CNT := 0;			-- 警告発生件数

	--引数
	P_TOP_DEPT_NO := I_TOP_DEPT_NO;

	-- (1) ジョブIDを取得
	V_JOB_ID := CMN.PRE_PROCESS(I_JOB_ID, I_EXEC_JOB_ID, C_PACKAGE_NAME);

	-- (2) プログラム開始情報をログに出力
	CMN.INFO(V_JOB_ID
			,C_PACKAGE_NAME
			,C_INFOLOG_NAME || 'を開始しました。');

    --（３）会計年月を取得する。
    V_FINAN_YM := CMN_OPER_ADMIN.GET_TOP_DEPT_FINAN_YM(P_TOP_DEPT_NO);

    -- システム日付を取得
	V_SYSDATE := SYSDATE;

    -- カウントゼロクリア
    V_IN_COUNT := 0;
    V_ERR_COUNT := 0;

	-- 本処理

	FOR R_MATERIAL_WK IN CUR_MATERIAL_WK LOOP

        -- 読込件数カウントアップ
        V_IN_COUNT := V_IN_COUNT + 1;
        -- ① エラーフラグ
        V_ERR_FLG := CONST_FLAG.C_FALSE;
        -- ② 部門存在チェック
        IF GET_V_DEPT_BASE_MAST(V_IN_COUNT, R_MATERIAL_WK.DEPT_NO, '部門番号') = 0 THEN
            V_ERR_FLG := CONST_FLAG.C_TRUE;
        END IF;
        -- ③ 部門番号チェック
        IF SUBSTR(P_TOP_DEPT_NO, 0, 3) <> SUBSTR(R_MATERIAL_WK.DEPT_NO, 0, 3) THEN
            V_ERR_FLG := CONST_FLAG.C_TRUE;
            V_MSG := '部門番号（先頭３ケタ）アンマッチエラー。' ||
            ' レコード番号＝['|| V_IN_COUNT || ']' ||
            ' 最上位部門番号＝['|| P_TOP_DEPT_NO || ']' ||
            ' 部門番号＝[' || R_MATERIAL_WK.DEPT_NO || ']';
            CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
        END IF;
        -- ④ 原材料払出区分チェック
        R_EDI_CODE_TYPE_CONV := NULL;
        BEGIN
            R_EDI_CODE_TYPE_CONV := GET_EDI_CODE_TYPE_CONV(
                                    V_IN_COUNT, P_TOP_DEPT_NO,
                                    CONST_TR_PGM_SALES.C_EDI_DISTINCTION_TYPE_MC,
                                    CONST_CMNNO.C_MATERIAL_TAKE_OUT_TYPE, -- Z0373
                                    R_MATERIAL_WK.MC_ACXFR_RSN_CD,
                                    R_MATERIAL_WK.SLIP_DATE,
                                    'ＭＣ他勘定振替理由ＣＤ');
        EXCEPTION
            WHEN OTHERS THEN
               -- エラーフラグ
                V_ERR_FLG := CONST_FLAG.C_TRUE;
        END;
        --区分マスタ情報を索引する。
        IF R_EDI_CODE_TYPE_CONV.TR_EDI_CODE_TYPE_CONV_ID IS NOT NULL THEN
            BEGIN
                R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(
                            P_TOP_DEPT_NO,
                            CONST_CMNNO.C_MATERIAL_TAKE_OUT_TYPE,
                            R_EDI_CODE_TYPE_CONV.CHAR_HEAD1);
            EXCEPTION
                WHEN OTHERS THEN
                    -- エラーフラグ
                    V_ERR_FLG := CONST_FLAG.C_TRUE;

                    V_MSG := '区分マスタ索引エラー（原材料払出区分）。'                     ||
                    ' レコード番号＝['              || V_IN_COUNT                           || ']' ||
                    ' ＭＣ他勘定振替理由ＣＤ＝['    || R_MATERIAL_WK.MC_ACXFR_RSN_CD        || ']' ||
                    ' 最上位部門番号＝['            || P_TOP_DEPT_NO                        || ']' ||
                    ' 共通番号＝['                  || CONST_CMNNO.C_MATERIAL_TAKE_OUT_TYPE || ']' ||
                    ' 区分番号＝['                  || R_EDI_CODE_TYPE_CONV.CHAR_HEAD1      || ']';
                    CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
            END;
        END IF;
        -- ⑤ 在庫種類区分チェック
        CHECK_INVENT_KIND_TYPE(V_IN_COUNT, R_MATERIAL_WK.INVENT_KIND_TYPE, V_ERR_FLG);

        -- ⑥ 会計年月チェック
        CHECK_FINAN_YM(V_IN_COUNT, V_FINAN_YM, R_MATERIAL_WK.FINAN_YM, 'ＭＣ会計年月', V_ERR_FLG);

        -- ⑦ 赤黒区分チェック
        BEGIN
            R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(
                        CONST_CMNNO.C_RED_BLACK_TYPE, -- Z0088
                        R_MATERIAL_WK.RED_BLACK_TYPE);
            EXCEPTION
                WHEN OTHERS THEN
                    -- エラーフラグ
                    V_ERR_FLG := CONST_FLAG.C_TRUE;
                    V_MSG := '区分マスタ索引エラー。'                   ||
                    ' レコード番号＝['  || V_IN_COUNT                   || ']' ||
                    ' 赤黒区分＝['      || R_MATERIAL_WK.RED_BLACK_TYPE || ']';
                    CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
        END;

        --（４）チェック判定を行う。
        IF V_ERR_FLG = CONST_FLAG.C_TRUE THEN
            V_ERR_COUNT := V_ERR_COUNT + 1;
        END IF;
        IF V_ERR_COUNT = 0 THEN
            UPDATE TR_MATERIAL_WK
               SET MATERIAL_TAKE_OUT_TYPE = R_EDI_CODE_TYPE_CONV.CHAR_HEAD1,
                   REG_DATE_TIME          = V_SYSDATE
			WHERE CURRENT OF CUR_MATERIAL_WK;
        END IF;


    END LOOP;

	-- 件数ログ表示
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '原材料経費払出ワーク　　　　　　読込件数: ' ||
        TO_CHAR(V_IN_COUNT,  '999,999')     || ' 件');
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '原材料経費払出ワーク　　　　　エラー件数: ' ||
        TO_CHAR(V_ERR_COUNT,  '999,999')    || ' 件');

	-- 正常終了情報をログに出力
	IF V_ERR_COUNT = 0 THEN
    	-- コミットする
    	COMMIT;
		CMN.INFO(V_JOB_ID
				,C_PACKAGE_NAME
				,C_INFOLOG_NAME || 'が正常終了しました。');
	ELSE
        ROLLBACK;
		-- プログラム異常終了情報をログに出力
		V_ERR_MSG := '原材料経費払出データエラーチェックにてエラーが発生しています。';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						NULL, NULL, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
	END IF;

	-- 後処理
	CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);

    RETURN V_END_CODE;

EXCEPTION
	WHEN OTHERS THEN
		-- ロールバック
		ROLLBACK;
		-- 異常終了コードをセット
		V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		-- プログラム異常終了情報をログに出力
		V_ERR_MSG := '予期せぬエラーが発生しました。';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						SQLCODE, SQLERRM, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
END CHECK_MATERIAL_TAKE_OUT;
-- *****************************************************************************
--　プログラム名 : 190_20_13_02 在庫残高データエラーチェック
--  @PARAM		I_JOB_ID			ジョブID
--  @PARAM		I_EXEC_JOB_ID		実行ユーザID
--  @PARAM		I_TOP_DEPT_NO		最上位部門番号
--  @RETURN		終了コード
-- *****************************************************************************
FUNCTION CHECK_INVENT_BALANCE_AMO(
    I_JOB_ID                    IN NUMBER      --ジョブＩＤ
    ,I_EXEC_JOB_ID              IN VARCHAR2    --実行ユーザーＩＤ
    ,I_TOP_DEPT_NO              IN VARCHAR2    --最上位部門番号
)RETURN NUMBER
IS
    C_PROC_NAME		CONSTANT	VARCHAR2(30)
								:= 'CHECK_INVENT_BALANCE_AMO';
	-- ログ出力用名称
	C_INFOLOG_NAME	CONSTANT	VARCHAR2(30)
								:= '在庫残高データエラーチェック';

	V_MSG						VARCHAR2(4000); -- メッセージ
	V_ERR_MSG					VARCHAR2(4000); -- エラーメッセージ

    -- 処理カウント
    V_IN_COUNT                  NUMBER;         --読込件数
    V_ERR_COUNT                 NUMBER;       	--エラー件数
    V_ERR_FLG                   VARCHAR2(1);    --エラーフラグ

    V_FINAN_YM                  VARCHAR(6);     --会計年月
    R_TYPE_MAST                 TYPE_MAST%ROWTYPE; --区分マスタ情報

	-- 抽出対象となる原材料在庫残高ワークを取得する
	CURSOR CUR_MATERIAL_INVENT_BAL_WK IS
        SELECT      A.*
        FROM        TR_MATERIAL_INVENT_BAL_WK A
        WHERE       A.TOP_DEPT_NO = P_TOP_DEPT_NO
        ORDER BY    A.ID;
        --FOR UPDATE;

BEGIN

	-- 初期化
	V_END_CODE := CONST_BATCH_EXIT_CODE.C_NORMAL_EXIT;
	V_WARN_CNT := 0;			-- 警告発生件数

	--引数
	P_TOP_DEPT_NO := I_TOP_DEPT_NO;

	-- (1) ジョブIDを取得
	V_JOB_ID := CMN.PRE_PROCESS(I_JOB_ID, I_EXEC_JOB_ID, C_PACKAGE_NAME);

	-- (2) プログラム開始情報をログに出力
	CMN.INFO(V_JOB_ID
			,C_PACKAGE_NAME
			,C_INFOLOG_NAME || 'を開始しました。');

    --（３）会計年月を取得する。
    V_FINAN_YM := CMN_OPER_ADMIN.GET_TOP_DEPT_FINAN_YM(P_TOP_DEPT_NO);

    -- システム日付を取得
	V_SYSDATE := SYSDATE;

    -- カウントゼロクリア
    V_IN_COUNT := 0;
    V_ERR_COUNT := 0;

	-- 本処理

	FOR R_MATERIAL_INVENT_BAL_WK IN CUR_MATERIAL_INVENT_BAL_WK LOOP

        -- 読込件数カウントアップ
        V_IN_COUNT := V_IN_COUNT + 1;
        -- ① エラーフラグ
        V_ERR_FLG := CONST_FLAG.C_FALSE;
        -- ② 在庫仕訳種別チェック
        CHECK_INVENT_JNL_KIND_TYPE(V_IN_COUNT,
                                   R_MATERIAL_INVENT_BAL_WK.INVENT_JNL_KIND_TYPE,
                                   V_ERR_FLG);
        -- ③ 会計年月チェック
        CHECK_FINAN_YM(V_IN_COUNT, V_FINAN_YM, R_MATERIAL_INVENT_BAL_WK.FINAN_YM, '会計年月', V_ERR_FLG);
        -- ④ 赤黒区分チェック
        BEGIN
            R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(
                        CONST_CMNNO.C_RED_BLACK_TYPE,
                        R_MATERIAL_INVENT_BAL_WK.RED_BLACK_TYPE);
            EXCEPTION
                WHEN OTHERS THEN
                    -- エラーフラグ
                    V_ERR_FLG := CONST_FLAG.C_TRUE;
                    V_MSG := '区分マスタ索引エラー。'                               ||
                    ' レコード番号＝['  || V_IN_COUNT                               || ']' ||
                    ' 赤黒区分＝['      || R_MATERIAL_INVENT_BAL_WK.RED_BLACK_TYPE  || ']';
                    CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
        END;

        --（４）チェック判定を行う。
        IF V_ERR_FLG = CONST_FLAG.C_TRUE THEN
            V_ERR_COUNT := V_ERR_COUNT + 1;
        END IF;
    END LOOP;

	-- 件数ログ表示
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '原材料在庫残高ワーク　　　　　　読込件数: ' ||
        TO_CHAR(V_IN_COUNT,  '999,999')     || ' 件');
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '原材料在庫残高ワーク　　　　　エラー件数: ' ||
        TO_CHAR(V_ERR_COUNT,  '999,999')    || ' 件');

	-- 正常終了情報をログに出力
	IF V_ERR_COUNT <> 0 THEN
		-- プログラム異常終了情報をログに出力
		V_ERR_MSG := '在庫残高データエラーチェックにてエラーが発生しています。';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						NULL, NULL, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
        -- 上記メッセージ出力後、終了処理する。
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
	END IF;
    -- 終了ログを出力する。
    CMN.INFO(V_JOB_ID
        ,C_PACKAGE_NAME
        ,C_INFOLOG_NAME || 'が正常終了しました。');
	-- 後処理
	CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);

    RETURN V_END_CODE;

EXCEPTION
	WHEN OTHERS THEN
		-- 異常終了コードをセット
		V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		-- プログラム異常終了情報をログに出力
		V_ERR_MSG := '予期せぬエラーが発生しました。';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						SQLCODE, SQLERRM, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
END CHECK_INVENT_BALANCE_AMO;

-- *****************************************************************************
--　プログラム名 : 190_20_14_02 製品出荷データエラーチェック
--  @PARAM		I_JOB_ID			ジョブID
--  @PARAM		I_EXEC_JOB_ID		実行ユーザID
--  @PARAM		I_TOP_DEPT_NO		最上位部門番号
--  @RETURN		終了コード
-- *****************************************************************************
FUNCTION CHECK_GOODS_OUT_GO(
    I_JOB_ID                    IN NUMBER      --ジョブＩＤ
    ,I_EXEC_JOB_ID              IN VARCHAR2    --実行ユーザーＩＤ
    ,I_TOP_DEPT_NO              IN VARCHAR2    --最上位部門番号
)RETURN NUMBER
IS
    C_PROC_NAME		CONSTANT	VARCHAR2(30)
								:= 'CHECK_GOODS_OUT_GO';
	-- ログ出力用名称
	C_INFOLOG_NAME	CONSTANT	VARCHAR2(30)
								:= '製品出荷データエラーチェック';

	V_MSG						VARCHAR2(4000); -- メッセージ
	V_ERR_MSG					VARCHAR2(4000); -- エラーメッセージ

    -- 処理カウント
    V_IN_COUNT                  NUMBER;         --読込件数
    V_ERR_COUNT                 NUMBER;       	--エラー件数
    V_ERR_FLG                   VARCHAR2(1);    --エラーフラグ
    V_PARAM_ERR_FLG             VARCHAR2(1);    -- 換算用エラーフラグ

    V_FINAN_YM                              VARCHAR(6);     --会計年月
    R_TYPE_MAST                             TYPE_MAST%ROWTYPE; --区分マスタ情報
    R_EDI_CODE_TYPE_CONV_PLACE              TR_EDI_CODE_TYPE_CONV%ROWTYPE; --ＥＤＩコード区分変換(商社) PLACE
    R_EDI_CODE_TYPE_CONV_UNIT               TR_EDI_CODE_TYPE_CONV%ROWTYPE; --ＥＤＩコード区分変換(商社) UNIT
    V_QTY                                   NUMBER; --換算後数量

	-- 抽出対象となる製品出荷ワークを取得する（複数明細）。
	CURSOR CUR_PRODUCT_SHIP_WK IS
        SELECT      A.*
        FROM        TR_PRODUCT_SHIP_WK A
        WHERE       A.TOP_DEPT_NO = P_TOP_DEPT_NO
        ORDER BY    A.ID
        FOR UPDATE;

BEGIN

	-- 初期化
	V_END_CODE := CONST_BATCH_EXIT_CODE.C_NORMAL_EXIT;
	V_WARN_CNT := 0;			-- 警告発生件数

	--引数
	P_TOP_DEPT_NO := I_TOP_DEPT_NO;

	-- (1) ジョブIDを取得
	V_JOB_ID := CMN.PRE_PROCESS(I_JOB_ID, I_EXEC_JOB_ID, C_PACKAGE_NAME);

	-- (2) プログラム開始情報をログに出力
	CMN.INFO(V_JOB_ID
			,C_PACKAGE_NAME
			,C_INFOLOG_NAME || 'を開始しました。');

    --（３）会計年月を取得する。
    V_FINAN_YM := CMN_OPER_ADMIN.GET_TOP_DEPT_FINAN_YM(P_TOP_DEPT_NO);

    -- システム日付を取得
	V_SYSDATE := SYSDATE;

    -- カウントゼロクリア
    V_IN_COUNT := 0;
    V_ERR_COUNT := 0;

	-- 本処理

	FOR R_PRODUCT_SHIP_WK IN CUR_PRODUCT_SHIP_WK LOOP

        -- 読込件数カウントアップ
        V_IN_COUNT := V_IN_COUNT + 1;
        -- ① エラーフラグ
        V_ERR_FLG := CONST_FLAG.C_FALSE;
        V_PARAM_ERR_FLG := CONST_FLAG.C_FALSE;
        -- ② 商品コードチェック
        IF GET_GOODS_MAST(V_IN_COUNT, R_PRODUCT_SHIP_WK.GOODS_CODE) = 0 THEN
            -- エラーフラグ
            V_ERR_FLG := CONST_FLAG.C_TRUE;
            V_PARAM_ERR_FLG := CONST_FLAG.C_TRUE;
        END IF;
        -- ② 赤黒区分チェック
        BEGIN
            R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(CONST_CMNNO.C_RED_BLACK_TYPE, R_PRODUCT_SHIP_WK.RED_BLACK_TYPE);
        EXCEPTION
            WHEN OTHERS THEN
                -- エラーフラグ
                V_ERR_FLG := CONST_FLAG.C_TRUE;
                V_MSG := '区分マスタ索引エラー。'                          ||
                ' レコード番号＝[' || V_IN_COUNT                           || ']' ||
                ' 赤黒区分＝['     || R_PRODUCT_SHIP_WK.RED_BLACK_TYPE     || ']';
                CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
        END;
        -- ③ 場所コードチェック
        -- a)	ＥＤＩコード区分変換(商社)を索引する（１件目のレコードの項目を取得後、クローズすること）。
        R_EDI_CODE_TYPE_CONV_PLACE := NULL;
        BEGIN
              R_EDI_CODE_TYPE_CONV_PLACE := GET_EDI_CODE_TYPE_CONV(
                                            V_IN_COUNT,
                                            P_TOP_DEPT_NO,
                                            CONST_TR_PGM_SALES.C_EDI_DISTINCTION_TYPE_MC,
                                            '100',
                                            R_PRODUCT_SHIP_WK.MC_PLACE_CODE,
                                            R_PRODUCT_SHIP_WK.SHIP_DATE,
                                            'ＭＣ場所コード');
        -- b)	レコードが取得できない場合、エラーフラグ（変数）をTRUEにし、エラーメッセージを出力する。
        EXCEPTION
            WHEN OTHERS THEN
                -- エラーフラグ
                V_ERR_FLG := CONST_FLAG.C_TRUE;

        END;
        -- c)	レコードが取得できた場合、ＥＤＩコード区分変換(商社)の項目をチェックする。
        IF R_EDI_CODE_TYPE_CONV_PLACE.TR_EDI_CODE_TYPE_CONV_ID IS NOT NULL THEN
            -- ｱ)	倉庫マスタを索引する。【倉庫存在チェック】
            IF GET_WAREHOUSE(V_IN_COUNT, P_TOP_DEPT_NO,
                             R_EDI_CODE_TYPE_CONV_PLACE.CHAR_HEAD1,
                             R_PRODUCT_SHIP_WK.MC_PLACE_CODE,
                             'ＭＣ場所コード') = 0 THEN
                -- エラーフラグ
                V_ERR_FLG := CONST_FLAG.C_TRUE;
            END IF;
            -- ｳ)	ＥＤＩコード区分変換（商社）．文字データ２≠NULLの場合、在庫置場マスタを索引する。
            IF R_EDI_CODE_TYPE_CONV_PLACE.CHAR_HEAD2 IS NOT NULL THEN
                IF GET_INVENT_PLACE(V_IN_COUNT, P_TOP_DEPT_NO,
                                    R_EDI_CODE_TYPE_CONV_PLACE.CHAR_HEAD1,
                                    R_EDI_CODE_TYPE_CONV_PLACE.CHAR_HEAD2,
                                    R_PRODUCT_SHIP_WK.MC_PLACE_CODE,
                                    'ＭＣ場所コード') = 0 THEN
                    -- エラーフラグ
                    V_ERR_FLG := CONST_FLAG.C_TRUE;
                END IF;
            END IF;
            -- ｵ) 区分マスタ情報を取得
            BEGIN
                R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(
                    P_TOP_DEPT_NO, CONST_CMNNO.C_STRONG_POINT_TYPE,
                    R_EDI_CODE_TYPE_CONV_PLACE.CHAR_HEAD3);
                EXCEPTION
                    WHEN OTHERS THEN
                        -- エラーフラグ
                        V_ERR_FLG := CONST_FLAG.C_TRUE;
                        V_MSG := '区分マスタ索引エラー（拠点）。' ||
                                ' レコード番号＝['   || V_IN_COUNT                               || ']' ||
                                ' ＭＣ場所コード＝[' || R_PRODUCT_SHIP_WK.MC_PLACE_CODE          || ']' ||
                                ' 倉庫番号＝['       || R_EDI_CODE_TYPE_CONV_PLACE.CHAR_HEAD1    || ']' ||
                                ' 置場番号＝['       || R_EDI_CODE_TYPE_CONV_PLACE.CHAR_HEAD2    || ']' ||
                                ' 拠点区分＝['       || R_EDI_CODE_TYPE_CONV_PLACE.CHAR_HEAD3    || ']';
                        CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
            END;
        END IF;
        -- ④ ＭＣ基準単位ＣＤチェック
        R_EDI_CODE_TYPE_CONV_UNIT := NULL;
        BEGIN
            R_EDI_CODE_TYPE_CONV_UNIT := GET_EDI_CODE_TYPE_CONV(
                                        V_IN_COUNT, P_TOP_DEPT_NO,
                                        CONST_TR_PGM_SALES.C_EDI_DISTINCTION_TYPE_MC,
                                        CONST_CMNNO.C_UNIT_TYPE,
                                        R_PRODUCT_SHIP_WK.MC_UNIT_CD,
                                        R_PRODUCT_SHIP_WK.SHIP_DATE,
                                        'ＭＣ基準単位ＣＤ');
            EXCEPTION
                WHEN OTHERS THEN
                    -- エラーフラグ
                    V_ERR_FLG := CONST_FLAG.C_TRUE;
                    V_PARAM_ERR_FLG := CONST_FLAG.C_TRUE;
            END;

        -- ⑤ 換算用エラーフラグ（変数）＝FALSEの場合、基準単位換算チェック
        IF V_PARAM_ERR_FLG = CONST_FLAG.C_FALSE THEN
            BEGIN
                V_QTY := CMN_GOODS_PARTS.CONVERT_GOODS_BASE_UNIT(
                        R_PRODUCT_SHIP_WK.GOODS_CODE,
                        1, R_EDI_CODE_TYPE_CONV_UNIT.CHAR_HEAD1,
                        NULL, NULL, P_TOP_DEPT_NO);
            EXCEPTION
                WHEN OTHERS THEN
                    -- エラーフラグ
                    V_ERR_FLG := CONST_FLAG.C_TRUE;
                    V_MSG := '基本単位換算エラー。'                                     ||
                    ' レコード番号＝['        || V_IN_COUNT                             || ']' ||
                    ' ＭＣ基準単位ＣＤ＝['    || R_PRODUCT_SHIP_WK.MC_UNIT_CD           || ']' ||
                    ' 単位区分＝['            || R_EDI_CODE_TYPE_CONV_UNIT.CHAR_HEAD1   || ']' ||
                    ' 商品コード＝['          || R_PRODUCT_SHIP_WK.GOODS_CODE           || ']';
                    CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
            END;
        END IF;

        -- ⑥ 会計年月チェック
        CHECK_FINAN_YM(V_IN_COUNT, V_FINAN_YM, R_PRODUCT_SHIP_WK.FINAN_YM, '会計年月', V_ERR_FLG);

        IF V_ERR_FLG = CONST_FLAG.C_TRUE THEN
            V_ERR_COUNT := V_ERR_COUNT + 1;
        END IF;

        IF V_ERR_COUNT = 0 THEN
            UPDATE TR_PRODUCT_SHIP_WK
               SET WAREHOUSE_NO       = R_EDI_CODE_TYPE_CONV_PLACE.CHAR_HEAD1,  --倉庫番号
                   INVENT_PLACE_NO    = R_EDI_CODE_TYPE_CONV_PLACE.CHAR_HEAD2,  --在庫置場番号
                   STRONG_POINT_TYPE  = R_EDI_CODE_TYPE_CONV_PLACE.CHAR_HEAD3,  --拠点区分
                   SHIP_QTY_UNIT_TYPE = R_EDI_CODE_TYPE_CONV_UNIT.CHAR_HEAD1,   --出荷数量単位区分
                   REG_DATE_TIME      = V_SYSDATE                               --登録日時
             WHERE CURRENT OF CUR_PRODUCT_SHIP_WK;
        END IF;

    END LOOP;

	-- 件数ログ表示
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '製品出荷ワーク　　　　　　読込件数: ' ||
        TO_CHAR(V_IN_COUNT,  '999,999')     || ' 件');
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '製品出荷ワーク　　　　　エラー件数: ' ||
        TO_CHAR(V_ERR_COUNT,  '999,999')    || ' 件');

	-- 正常終了情報をログに出力
	IF V_ERR_COUNT <> 0 THEN
        ROLLBACK;
		-- プログラム異常終了情報をログに出力
		V_ERR_MSG := '製品出荷データエラーチェックにてエラーが発生しています。';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						NULL, NULL, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
        -- 上記メッセージ出力後、終了処理する。
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
    ELSE
        COMMIT;
        CMN.INFO(V_JOB_ID
				,C_PACKAGE_NAME
				,C_INFOLOG_NAME || 'が正常終了しました。');
	END IF;

	-- 後処理
	CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);

    RETURN V_END_CODE;

EXCEPTION
	WHEN OTHERS THEN
        ROLLBACK;
		-- 異常終了コードをセット
		V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		-- プログラム異常終了情報をログに出力
		V_ERR_MSG := '予期せぬエラーが発生しました。';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						SQLCODE, SQLERRM, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
END CHECK_GOODS_OUT_GO;

-- *****************************************************************************
--　プログラム名 : 190_20_16_02 製造原価データエラーチェック
--  @PARAM		I_JOB_ID			ジョブID
--  @PARAM		I_EXEC_JOB_ID		実行ユーザID
--  @PARAM		I_TOP_DEPT_NO		最上位部門番号
--  @RETURN		終了コード
-- *****************************************************************************
FUNCTION CHECK_PROD_COST(
        I_JOB_ID                    IN NUMBER      --ジョブＩＤ
        ,I_EXEC_JOB_ID              IN VARCHAR2    --実行ユーザーＩＤ
        ,I_TOP_DEPT_NO              IN VARCHAR2    --最上位部門番号
    )RETURN NUMBER
IS
    C_PROC_NAME		CONSTANT	VARCHAR2(30)
								:= 'CHECK_PROD_COST';
	-- ログ出力用名称
	C_INFOLOG_NAME	CONSTANT	VARCHAR2(30)
								:= '製造原価データエラーチェック';

	V_ERR_MSG					VARCHAR2(4000); -- エラーメッセージ

    -- 処理カウント
    V_IN_COUNT                  NUMBER;         --読込件数
    V_ERR_COUNT                 NUMBER;       	--エラー件数
    V_ERR_FLG                   VARCHAR2(1);    --エラーフラグ

    V_FINAN_YM                              VARCHAR(6);     --会計年月
    V_FINAN_YEAR                            VARCHAR2(4);    --会計年度
    V_PROD_COST_FINAN_YEAR                  VARCHAR2(4);    --会計年度（製造原価ワークより）
    V_CONTINUE_FLG                          VARCHAR2(1);
    R_EDI_CODE_TYPE_CONV                    TR_EDI_CODE_TYPE_CONV%ROWTYPE; --ＥＤＩコード区分変換
    V_FINAN_DATE                            DATE; --会計年月の１日
    R_TYPE_MAST                             TYPE_MAST%ROWTYPE; --区分マスタ情報
    --抽出対象となる製造原価ワークを取得する（複数明細）。
	CURSOR CUR_PROD_COST_WK IS
        SELECT      A.*
        FROM        TR_PROD_COST_WK A
        WHERE       A.TOP_DEPT_NO = P_TOP_DEPT_NO
        ORDER BY    A.ID
        FOR         UPDATE;
BEGIN

	-- 初期化
	V_END_CODE := CONST_BATCH_EXIT_CODE.C_NORMAL_EXIT;
	V_WARN_CNT := 0;			-- 警告発生件数

	--引数
	P_TOP_DEPT_NO := I_TOP_DEPT_NO;

	-- (1) ジョブIDを取得
	V_JOB_ID := CMN.PRE_PROCESS(I_JOB_ID, I_EXEC_JOB_ID, C_PACKAGE_NAME);

	-- (2) プログラム開始情報をログに出力
	CMN.INFO(V_JOB_ID
			,C_PACKAGE_NAME
			,C_INFOLOG_NAME || 'を開始しました。');

    --（３）会計年月を取得する。
    V_FINAN_YM := CMN_OPER_ADMIN.GET_TOP_DEPT_FINAN_YM(P_TOP_DEPT_NO);

    --（４）決算年度を取得する。
    V_FINAN_YEAR := CMN_UTL_CLNDR.GET_FINAN_YEAR(V_FINAN_YM);

    -- システム日付を取得
	V_SYSDATE := SYSDATE;

    -- カウントゼロクリア
    V_IN_COUNT := 0;
    V_ERR_COUNT := 0;

	-- 本処理

	FOR R_PROD_COST_WK IN CUR_PROD_COST_WK LOOP
        -- 読込件数カウントアップ
        V_IN_COUNT := V_IN_COUNT + 1;
        -- ① エラーフラグ
        V_ERR_FLG := CONST_FLAG.C_FALSE;
        V_CONTINUE_FLG := CONST_FLAG.C_TRUE;
        -- ② 商品コードチェック
        IF GET_GOODS_MAST(V_IN_COUNT, R_PROD_COST_WK.GOODS_CODE) = 0 THEN
            -- エラーフラグ
            V_ERR_FLG := CONST_FLAG.C_TRUE;
        END IF;
		IF SUBSTR(R_PROD_COST_WK.GOODS_CODE, 0, 3) <> SUBSTR(P_TOP_DEPT_NO, 0, 3) THEN
			-- エラーフラグ
            V_ERR_FLG := CONST_FLAG.C_TRUE;
			V_ERR_MSG := '商品コード（先頭３ケタ）アンマッチエラー。' ||
						'レコード番号＝['		||	V_IN_COUNT					|| ']' ||
						'商品コード＝['		 ||	R_PROD_COST_WK.GOODS_CODE	 || ']' ||
						'最上位部門番号＝['	   || P_TOP_DEPT_NO				   || ']';
			CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_ERR_MSG);
		END IF;
        -- ④ 年度チェック
        V_PROD_COST_FINAN_YEAR := CMN_UTL_CLNDR.GET_FINAN_YEAR(R_PROD_COST_WK.FINAN_YM);
        CHECK_FINAN_YEAR(V_IN_COUNT, V_FINAN_YEAR, V_PROD_COST_FINAN_YEAR, V_ERR_FLG);
        -- ⑤ 会計年月チェック
        CHECK_FINAN_YM(V_IN_COUNT, V_FINAN_YM, R_PROD_COST_WK.FINAN_YM, 'ＭＣ会計年月', V_ERR_FLG);
        -- ⑥ 在庫計算方法区分チェック
        CHECK_INVENT_CALC_TYPE(V_IN_COUNT, R_PROD_COST_WK.INVENT_CALC_TYPE, V_ERR_FLG);
        -- ⑦ ＭＣ計算グループＣＤチェック
        -- a) ＥＤＩコード区分変換(商社)を索引する（１件目のレコードの項目を取得後、クローズすること）。
        V_FINAN_DATE := TO_DATE(V_FINAN_YM || '01', 'YYYYMMDD');
        R_EDI_CODE_TYPE_CONV := NULL;
        BEGIN
        R_EDI_CODE_TYPE_CONV := GET_EDI_CODE_TYPE_CONV(
                                V_IN_COUNT,
                                P_TOP_DEPT_NO,
                                CONST_TR_PGM_SALES.C_EDI_DISTINCTION_TYPE_MC,
                                '110',
                                R_PROD_COST_WK.MC_CALC_GRP_CD,
                                V_FINAN_DATE,
                                'ＭＣ計算グループＣＤ'
                            );
        EXCEPTION
            WHEN OTHERS THEN
                V_ERR_FLG := CONST_FLAG.C_TRUE;
        END;
        IF R_EDI_CODE_TYPE_CONV.TR_EDI_CODE_TYPE_CONV_ID IS NOT NULL THEN
            -- c)	レコードが取得できた場合、ＥＤＩコード区分変換(商社)の項目をチェックする。
            -- ｱ)	倉庫マスタを索引する。【倉庫存在チェック】
            IF GET_WAREHOUSE(V_IN_COUNT, P_TOP_DEPT_NO,
                R_EDI_CODE_TYPE_CONV.CHAR_HEAD1,
                R_PROD_COST_WK.MC_CALC_GRP_CD,
                'ＭＣ計算グループＣＤ') = 0 THEN
                V_ERR_FLG := CONST_FLAG.C_TRUE;
                V_CONTINUE_FLG := CONST_FLAG.C_FALSE;
            END IF;
            -- ｳ)	ＥＤＩコード区分変換（商社）．文字データ２≠NULLの場合、在庫置場マスタを索引する
            IF V_CONTINUE_FLG = CONST_FLAG.C_TRUE THEN
                IF R_EDI_CODE_TYPE_CONV.CHAR_HEAD2 IS NOT NULL THEN
                    IF GET_INVENT_PLACE(V_IN_COUNT, P_TOP_DEPT_NO,
                        R_EDI_CODE_TYPE_CONV.CHAR_HEAD1,
                        R_EDI_CODE_TYPE_CONV.CHAR_HEAD2,
                        R_PROD_COST_WK.MC_CALC_GRP_CD,
                        'ＭＣ計算グループＣＤ') = 0 THEN
                        V_ERR_FLG := CONST_FLAG.C_TRUE;
                        V_CONTINUE_FLG := CONST_FLAG.C_FALSE;
                    END IF;
                END IF;
                -- 区分マスタ情報を取得
                IF V_CONTINUE_FLG = CONST_FLAG.C_TRUE THEN
                    BEGIN
                    R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(P_TOP_DEPT_NO,
                                    CONST_CMNNO.C_STRONG_POINT_TYPE, R_EDI_CODE_TYPE_CONV.CHAR_HEAD3);
                    EXCEPTION
                        WHEN OTHERS THEN
                            V_ERR_FLG := CONST_FLAG.C_TRUE;
                            V_ERR_MSG := '区分マスタ索引エラー（拠点）。' ||
                                     ' レコード番号＝['          || V_IN_COUNT || ']' ||
                                     ' ＭＣ計算グループＣＤ＝['  || R_PROD_COST_WK.MC_CALC_GRP_CD    || ']' ||
                                     ' 倉庫番号＝['              || R_EDI_CODE_TYPE_CONV.CHAR_HEAD1  || ']' ||
                                     ' 置場番号＝['              || R_EDI_CODE_TYPE_CONV.CHAR_HEAD2  || ']' ||
                                     ' 拠点区分＝['              || R_EDI_CODE_TYPE_CONV.CHAR_HEAD3  || ']';
                            CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_ERR_MSG);
                    END;
                END IF;
            END IF;
        END IF;
        IF V_ERR_FLG = CONST_FLAG.C_TRUE THEN
            V_ERR_COUNT := V_ERR_COUNT + 1;
        END IF;
        IF V_ERR_COUNT = 0 THEN
            UPDATE TR_PROD_COST_WK T
               SET T.YEAR              = V_FINAN_YEAR,
                   T.WAREHOUSE_NO      = R_EDI_CODE_TYPE_CONV.CHAR_HEAD1,
                   T.INVENT_PLACE_NO   = R_EDI_CODE_TYPE_CONV.CHAR_HEAD2,
                   T.STRONG_POINT_TYPE = R_EDI_CODE_TYPE_CONV.CHAR_HEAD3,
                   T.REG_DATE_TIME     = V_SYSDATE
            WHERE CURRENT OF CUR_PROD_COST_WK;
        END IF;

    END LOOP;

	-- 件数ログ表示
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '製造原価ワーク　　　　　　読込件数: ' ||
        TO_CHAR(V_IN_COUNT,  '999,999')     || ' 件');
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '製造原価ワーク　　　　　エラー件数: ' ||
        TO_CHAR(V_ERR_COUNT,  '999,999')    || ' 件');

	-- 正常終了情報をログに出力
	IF V_ERR_COUNT <> 0 THEN
        ROLLBACK;
		-- プログラム異常終了情報をログに出力
		V_ERR_MSG := '製造原価データエラーチェックにてエラーが発生しています。';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						NULL, NULL, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
        -- 上記メッセージ出力後、終了処理する。
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
    ELSE
        COMMIT;
        CMN.INFO(V_JOB_ID
				,C_PACKAGE_NAME
				,C_INFOLOG_NAME || 'が正常終了しました。');
	END IF;

	-- 後処理
	CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);

    RETURN V_END_CODE;

EXCEPTION
	WHEN OTHERS THEN
        ROLLBACK;
		-- 異常終了コードをセット
		V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		-- プログラム異常終了情報をログに出力
		V_ERR_MSG := '予期せぬエラーが発生しました。';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						SQLCODE, SQLERRM, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;

END CHECK_PROD_COST;

-- *****************************************************************************
--　プログラム名 : 190_20_17_02 商品マスタデータエラーチェック
--  @PARAM		I_JOB_ID			ジョブID
--  @PARAM		I_EXEC_JOB_ID		実行ユーザID
--  @PARAM		I_TOP_DEPT_NO		最上位部門番号
--  @RETURN		終了コード
-- *****************************************************************************
FUNCTION CHECK_GOODS_MAST(
    I_JOB_ID                    IN NUMBER      --ジョブＩＤ
    ,I_EXEC_JOB_ID              IN VARCHAR2    --実行ユーザーＩＤ
    ,I_TOP_DEPT_NO              IN VARCHAR2    --最上位部門番号
)RETURN NUMBER
IS
    C_PROC_NAME		CONSTANT	VARCHAR2(30)
								:= 'CHECK_GOODS_MAST';
	-- ログ出力用名称
	C_INFOLOG_NAME	CONSTANT	VARCHAR2(30)
								:= '商品マスタデータエラーチェック';

	V_MSG						VARCHAR2(4000); -- メッセージ
	V_ERR_MSG					VARCHAR2(4000); -- エラーメッセージ

    -- 処理カウント
    V_IN_COUNT                  NUMBER;         --読込件数
    V_ERR_COUNT                 NUMBER;       	--エラー件数
    V_ERR_FLG                   VARCHAR2(1);    --エラーフラグ

    R_TYPE_MAST                             TYPE_MAST%ROWTYPE; --区分マスタ情報
    R_EDI_CODE_TYPE_CONV_UNIT               TR_EDI_CODE_TYPE_CONV%ROWTYPE; --ＥＤＩコード区分変換(商社) UNIT
    V_OPER_LATE_DATE                        DATE; -- 運用当日日付

	-- 抽出対象となる商品マスタワークを取得する（複数明細）。
	CURSOR CUR_GOODS_MAST_WK IS
        SELECT      A.*
        FROM        TR_GOODS_MAST_WK A
        WHERE       A.TOP_DEPT_NO = P_TOP_DEPT_NO
        ORDER BY    A.ID
        FOR UPDATE;

BEGIN

	-- 初期化
	V_END_CODE := CONST_BATCH_EXIT_CODE.C_NORMAL_EXIT;
	V_WARN_CNT := 0;			-- 警告発生件数

	--引数
	P_TOP_DEPT_NO := I_TOP_DEPT_NO;

	-- (1) ジョブIDを取得
	V_JOB_ID := CMN.PRE_PROCESS(I_JOB_ID, I_EXEC_JOB_ID, C_PACKAGE_NAME);

	-- (2) プログラム開始情報をログに出力
	CMN.INFO(V_JOB_ID
			,C_PACKAGE_NAME
			,C_INFOLOG_NAME || 'を開始しました。');

    --（３）運用当日日付を取得する。
    V_OPER_LATE_DATE := CMN_OPER_ADMIN.GET_LATE_DATE;

    -- システム日付を取得
	V_SYSDATE := SYSDATE;

    -- カウントゼロクリア
    V_IN_COUNT := 0;
    V_ERR_COUNT := 0;

	-- 本処理

	FOR R_GOODS_MAST_WK IN CUR_GOODS_MAST_WK LOOP

        -- 読込件数カウントアップ
        V_IN_COUNT := V_IN_COUNT + 1;
        -- ① エラーフラグ
        V_ERR_FLG := CONST_FLAG.C_FALSE;
        --①-1	商品コードチェック
        IF SUBSTR(R_GOODS_MAST_WK.TOP_DEPT_NO, 0, 3) <> SUBSTR(R_GOODS_MAST_WK.GOODS_CODE, 0, 3) THEN
            --エラーフラグ
            V_ERR_FLG := CONST_FLAG.C_TRUE;
            V_MSG := '商品コードエラー（商品コード頭3桁'
                    || SUBSTR(R_GOODS_MAST_WK.TOP_DEPT_NO, 0, 3)  || '以外は連携不可）'
                    || ' レコード番号＝['                         || V_IN_COUNT                    || ']'
                    || ' 商品コード＝['                           || R_GOODS_MAST_WK.GOODS_CODE    || ']';
            CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
        END IF;
        -- ② ＭＣ基準単位ＣＤチェック
        R_EDI_CODE_TYPE_CONV_UNIT := NULL;
        BEGIN
            R_EDI_CODE_TYPE_CONV_UNIT := GET_EDI_CODE_TYPE_CONV(
                                        V_IN_COUNT,
                                        P_TOP_DEPT_NO,
                                        CONST_TR_PGM_SALES.C_EDI_DISTINCTION_TYPE_MC,
                                        CONST_CMNNO.C_UNIT_TYPE,
                                        R_GOODS_MAST_WK.MC_UNIT_CD,
                                        V_OPER_LATE_DATE,
                                        'ＭＣ基準単位ＣＤ');
        EXCEPTION
            WHEN OTHERS THEN
                -- エラーフラグ
                V_ERR_FLG := CONST_FLAG.C_TRUE;
        END;
        IF R_EDI_CODE_TYPE_CONV_UNIT.TR_EDI_CODE_TYPE_CONV_ID IS NOT NULL THEN
            BEGIN
                R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(
                            CONST_CMNNO.C_UNIT_TYPE,
                            R_EDI_CODE_TYPE_CONV_UNIT.CHAR_HEAD1);
            EXCEPTION
                WHEN OTHERS THEN
                    V_MSG := '区分マスタ索引エラー。' ||
                    ' レコード番号＝['          || V_IN_COUNT                           || ']' ||
                    ' ＭＣ基準単位ＣＤ＝['      || R_GOODS_MAST_WK.MC_UNIT_CD           || ']' ||
                    ' 単位区分＝['              || R_EDI_CODE_TYPE_CONV_UNIT.CHAR_HEAD1 || ']';
                    CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
                    V_ERR_FLG := CONST_FLAG.C_TRUE;
            END;
        END IF;
        -- ③ 在庫種類区分チェック
        IF R_GOODS_MAST_WK.INVENT_KIND_TYPE <> CONST_TR_PGM_SALES.C_INVENT_SORT_TYPE_MATERIAL
            AND R_GOODS_MAST_WK.INVENT_KIND_TYPE <> CONST_TR_PGM_SALES.C_INVENT_SORT_TYPE_STORED
            AND R_GOODS_MAST_WK.INVENT_KIND_TYPE <> CONST_TR_PGM_SALES.C_INVENT_SORT_TYPE_PRODUCT
        THEN
            V_MSG := '在庫種類対象外エラー。' ||
            ' レコード番号＝['   || V_IN_COUNT                          || ']' ||
            ' 在庫種類区分＝['   || R_GOODS_MAST_WK.INVENT_KIND_TYPE    || ']';
            CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
            V_ERR_FLG := CONST_FLAG.C_TRUE;
        END IF;

        IF V_ERR_FLG = CONST_FLAG.C_TRUE THEN
            V_ERR_COUNT := V_ERR_COUNT + 1;
        END IF;
        IF V_ERR_COUNT = 0 THEN
            UPDATE TR_GOODS_MAST_WK
               SET REG_DATE_TIME  = V_SYSDATE,
                   UNIT_TYPE      = R_EDI_CODE_TYPE_CONV_UNIT.CHAR_HEAD1
            WHERE CURRENT OF CUR_GOODS_MAST_WK;
        END IF;

    END LOOP;

	-- 件数ログ表示
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '商品マスタワーク　　　　　　読込件数: ' ||
        TO_CHAR(V_IN_COUNT,  '999,999')     || ' 件');
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '商品マスタワーク　　　　　エラー件数: ' ||
        TO_CHAR(V_ERR_COUNT,  '999,999')    || ' 件');

	-- 正常終了情報をログに出力
	IF V_ERR_COUNT <> 0 THEN
        ROLLBACK;
		-- プログラム異常終了情報をログに出力
		V_ERR_MSG := '商品マスタデータエラーチェックにてエラーが発生しています。';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						NULL, NULL, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
        -- 上記メッセージ出力後、終了処理する。
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
    ELSE
        COMMIT;
        CMN.INFO(V_JOB_ID
				,C_PACKAGE_NAME
				,C_INFOLOG_NAME || 'が正常終了しました。');
	END IF;

	-- 後処理
	CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);

    RETURN V_END_CODE;

EXCEPTION
	WHEN OTHERS THEN
        ROLLBACK;
		-- 異常終了コードをセット
		V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		-- プログラム異常終了情報をログに出力
		V_ERR_MSG := '予期せぬエラーが発生しました。';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						SQLCODE, SQLERRM, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
END CHECK_GOODS_MAST;

-- *****************************************************************************
--　プログラム名 : 190_20_19_02   仕掛原価データエラーチェック
--  @PARAM		I_JOB_ID			ジョブID
--  @PARAM		I_EXEC_JOB_ID		実行ユーザID
--  @PARAM		I_TOP_DEPT_NO		最上位部門番号
--  @RETURN		終了コード
-- *****************************************************************************
FUNCTION CHECK_IN_PROCESS_COST(
    I_JOB_ID                    IN NUMBER      --ジョブＩＤ
    ,I_EXEC_JOB_ID              IN VARCHAR2    --実行ユーザーＩＤ
    ,I_TOP_DEPT_NO              IN VARCHAR2    --最上位部門番号
)RETURN NUMBER
IS
    C_PROC_NAME		CONSTANT	VARCHAR2(30)
								:= 'CHECK_IN_PROCESS_COST';
	-- ログ出力用名称
	C_INFOLOG_NAME	CONSTANT	VARCHAR2(30)
								:= '仕掛原価データエラーチェック';

	V_ERR_MSG					VARCHAR2(4000); -- エラーメッセージ

    -- 処理カウント
    V_IN_COUNT                  NUMBER;         --読込件数
    V_ERR_COUNT                 NUMBER;       	--エラー件数
    V_ERR_FLG                   VARCHAR2(1);    --エラーフラグ

    R_TYPE_MAST                             TYPE_MAST%ROWTYPE; --区分マスタ情報
	V_FINAN_YM								VARCHAR2(6); -- 会計年月
	R_TR_COMMENCE_COST_WK					TR_COMMENCE_COST_WK%ROWTYPE; -- 仕掛原価ワーク（商社）

	-- （１） 抽出対象となる仕掛原価ワークを取得する（複数明細）。
	CURSOR CUR_TR_COMMENCE_COST_WK IS
	SELECT *
	  FROM TR_COMMENCE_COST_WK A
	 WHERE A.TOP_DEPT_NO = P_TOP_DEPT_NO
	 ORDER BY A.ID;

BEGIN

	-- 初期化
	V_END_CODE := CONST_BATCH_EXIT_CODE.C_NORMAL_EXIT;
	V_WARN_CNT := 0;			-- 警告発生件数

	--引数
	P_TOP_DEPT_NO := I_TOP_DEPT_NO;

	-- (1) ジョブIDを取得
	V_JOB_ID := CMN.PRE_PROCESS(I_JOB_ID, I_EXEC_JOB_ID, C_PACKAGE_NAME);

	-- (2) プログラム開始情報をログに出力
	CMN.INFO(V_JOB_ID
			,C_PACKAGE_NAME
			,C_INFOLOG_NAME || 'を開始しました。');

	--（３）	会計年月を取得する。
	V_FINAN_YM := CMN_OPER_ADMIN.GET_TOP_DEPT_FINAN_YM(P_TOP_DEPT_NO);

    -- カウントゼロクリア
    V_IN_COUNT := 0;
    V_ERR_COUNT := 0;

	-- ※対象のレコード（複数）について（２）～（４）を、
	-- 読込んだ明細が無くなるまで繰り返し行う。
	FOR R_TR_COMMENCE_COST_WK IN CUR_TR_COMMENCE_COST_WK LOOP
		-- （２） 仕掛原価ワークの読込件数をカウントする。
		V_IN_COUNT := V_IN_COUNT + 1;

		-- （３） チェックを行う。
		-- ① エラーフラグ（変数）
		V_ERR_FLG := CONST_FLAG.C_FALSE;

		-- ② 在庫仕訳種別チェック
		IF NVL(R_TR_COMMENCE_COST_WK.COMMENCE_INV_JNL_TYPE, ' ')
				<> CONST_PGM_CMN.C_COMMENCE_INV_JNL_TYPE_PREV
			AND NVL(R_TR_COMMENCE_COST_WK.COMMENCE_INV_JNL_TYPE, ' ')
				<> CONST_PGM_CMN.C_COMMENCE_INV_JNL_TYPE_PRES
		THEN
			V_ERR_FLG := CONST_FLAG.C_TRUE;
			V_ERR_MSG := '区分マスタ索引エラー'
						|| '	レコード番号＝' || V_IN_COUNT
						|| '	在庫仕訳種別区分＝' || R_TR_COMMENCE_COST_WK.COMMENCE_INV_JNL_TYPE;
			CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_ERR_MSG);
		END IF;
		-- ③ 会計年月チェック
		IF V_FINAN_YM > R_TR_COMMENCE_COST_WK.FINAN_YM THEN
			V_ERR_FLG := CONST_FLAG.C_TRUE;
			V_ERR_MSG := '会計年月エラー'
						|| '	レコード番号＝' || V_IN_COUNT
						|| '	会計年月＝' || V_FINAN_YM
						|| '	会計年月＝' || R_TR_COMMENCE_COST_WK.FINAN_YM;
			CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_ERR_MSG);
		END IF;

		-- ④ 赤黒区分チェック
		BEGIN
			R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(
                                        CONST_CMNNO.C_RED_BLACK_TYPE,
                                        R_TR_COMMENCE_COST_WK.RED_BLACK_TYPE);
		EXCEPTION
			WHEN OTHERS THEN
                V_ERR_FLG := CONST_FLAG.C_TRUE;
                V_ERR_MSG := '区分マスタ索引エラー'
						|| '	レコード番号＝' || V_IN_COUNT
						|| '	赤黒区分＝' || R_TR_COMMENCE_COST_WK.RED_BLACK_TYPE;
                CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_ERR_MSG);
		END;

		-- （４） チェック判定を行う。
		IF V_ERR_FLG = CONST_FLAG.C_TRUE THEN
			V_ERR_COUNT := V_ERR_COUNT + 1;
		END IF;
	END LOOP;

	-- 3 後処理
	-- （１） 情報ログを出力する
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '仕掛原価ワーク　　　　　　読込件数: ' ||
        TO_CHAR(V_IN_COUNT,  '999,999')     || ' 件');
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '仕掛原価ワーク　　　　　エラー件数: ' ||
        TO_CHAR(V_ERR_COUNT,  '999,999')    || ' 件');


	-- （２） エラー件数 ≠0 なら、エラーメッセージを出力する。
	IF V_ERR_COUNT != 0 THEN
		V_ERR_MSG := '仕掛原価データエラーチェックにてエラーが発生しています。';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
					C_PACKAGE_NAME, C_INFOLOG_NAME, NULL, NULL, V_ERR_MSG);
	END IF;
	-- （３） 終了ログを出力する
	CMN.INFO(V_JOB_ID, C_PACKAGE_NAME, C_INFOLOG_NAME || 'が正常終了しました。');

	-- （４） 終了処理する
	CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);

    RETURN V_END_CODE;

EXCEPTION
	WHEN OTHERS THEN
        ROLLBACK;
		-- 異常終了コードをセット
		V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		-- プログラム異常終了情報をログに出力
		V_ERR_MSG := '予期せぬエラーが発生しました。';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						SQLCODE, SQLERRM, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
END CHECK_IN_PROCESS_COST;
-- *****************************************************************************
--　プログラム名 : 190_20_21_02   製品在庫表原価実績データエラーチェック
--  @PARAM		I_JOB_ID			ジョブID
--  @PARAM		I_EXEC_JOB_ID		実行ユーザID
--  @PARAM		I_TOP_DEPT_NO		最上位部門番号
--  @RETURN		終了コード
-- *****************************************************************************
FUNCTION CHECK_IN_PROCESS_COST_ACT(
    I_JOB_ID                    IN NUMBER      --ジョブＩＤ
    ,I_EXEC_JOB_ID              IN VARCHAR2    --実行ユーザーＩＤ
    ,I_TOP_DEPT_NO              IN VARCHAR2    --最上位部門番号
)RETURN NUMBER
IS
    C_PROC_NAME		CONSTANT	VARCHAR2(30)
								:= 'CHECK_IN_PROCESS_COST_ACT';
	-- ログ出力用名称
	C_INFOLOG_NAME	CONSTANT	VARCHAR2(50)
								:= '製品在庫表原価実績データエラーチェック';

	V_ERR_MSG					VARCHAR2(4000); -- エラーメッセージ

    -- 処理カウント
    V_IN_COUNT                  NUMBER;         --読込件数
    V_ERR_COUNT                 NUMBER;       	--エラー件数
    V_ERR_FLG                   VARCHAR2(1);    --エラーフラグ

    R_TYPE_MAST                             TYPE_MAST%ROWTYPE; --区分マスタ情報
	V_FINAN_YM								VARCHAR2(6); -- 会計年月

	R_TR_PROD_INV_COST_ACT_WK					TR_PROD_INV_COST_ACT_WK%ROWTYPE; -- 仕掛原価ワーク（商社）

-- （１） 抽出対象となる製品在庫表原価実績ワークを取得する（複数明細）。
	CURSOR CUR_TR_PROD_INV_COST_ACT_WK IS
	SELECT *
	  FROM TR_PROD_INV_COST_ACT_WK A
	 WHERE  A.TOP_DEPT_NO = P_TOP_DEPT_NO
	 ORDER BY A.TR_PROD_INV_COST_ACT_WK_ID;

BEGIN
	
	-- 初期化
	V_END_CODE := CONST_BATCH_EXIT_CODE.C_NORMAL_EXIT;
	V_WARN_CNT := 0;			-- 警告発生件数
	--引数
	P_TOP_DEPT_NO := I_TOP_DEPT_NO;

	-- (1) ジョブIDを取得
	V_JOB_ID := CMN.PRE_PROCESS(I_JOB_ID, I_EXEC_JOB_ID, C_PACKAGE_NAME);

	-- (2) プログラム開始情報をログに出力
	CMN.INFO(V_JOB_ID
			,C_PACKAGE_NAME
			,C_INFOLOG_NAME || 'を開始しました。');

	--（３）	会計年月を取得する。
	V_FINAN_YM := CMN_OPER_ADMIN.GET_TOP_DEPT_FINAN_YM(P_TOP_DEPT_NO);

    -- カウントゼロクリア
    V_IN_COUNT := 0;
    V_ERR_COUNT := 0;

	-- ※対象のレコード（複数）について（２）～（４）を、
	-- 読込んだ明細が無くなるまで繰り返し行う。
	FOR R_TR_PROD_INV_COST_ACT_WK IN CUR_TR_PROD_INV_COST_ACT_WK LOOP
		-- （２） 製品在庫表原価実績ワークの読込件数をカウントする。
		V_IN_COUNT := V_IN_COUNT + 1;

		-- （３） チェックを行う。
		-- ① エラーフラグ（変数）
		V_ERR_FLG := CONST_FLAG.C_FALSE;
		
		-- ② 会計年月チェック
		IF  V_FINAN_YM > R_TR_PROD_INV_COST_ACT_WK.FINAN_YM
		THEN
			V_ERR_FLG := CONST_FLAG.C_TRUE;
			V_ERR_MSG := '会計年月エラー'
						|| '	レコード番号＝' || V_IN_COUNT
						|| '	Ｌ２会計年月＝' || V_FINAN_YM
						|| '	,会計年月＝'    || R_TR_PROD_INV_COST_ACT_WK.FINAN_YM;
			CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_ERR_MSG);
		END IF;
		-- ③ 商品コードチェック
		/*IF GET_GOODS_MAST(V_IN_COUNT, R_TR_PROD_INV_COST_ACT_WK.GOODS_CODE) = 0
		THEN
            V_ERR_FLG := CONST_FLAG.C_TRUE;
			V_ERR_MSG := '商品マスタ索引エラー'
						|| '	レコード番号＝' || V_IN_COUNT
						|| '	品目コード＝'   || R_TR_PROD_INV_COST_ACT_WK.GOODS_CODE;
			CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_ERR_MSG);
		END IF;*/

		IF SUBSTR(R_TR_PROD_INV_COST_ACT_WK.GOODS_CODE, 0, 3) <> SUBSTR(P_TOP_DEPT_NO, 0, 3) 
		THEN
			-- エラーフラグ
            V_ERR_FLG := CONST_FLAG.C_TRUE;
			V_ERR_MSG := '商品コード（先頭３ケタ）アンマッチエラー。' 					  ||
						'レコード番号＝['		||	V_IN_COUNT								|| ']' ||
						'商品コード＝['		 ||	R_TR_PROD_INV_COST_ACT_WK.GOODS_CODE	 || ']' ||
						'最上位部門番号＝['	   || P_TOP_DEPT_NO				   			   || ']';
			CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_ERR_MSG);
		END IF;
		-- ④ 親商品コードチェック
		IF GET_GOODS_MAST(V_IN_COUNT, R_TR_PROD_INV_COST_ACT_WK.PARENT_GOODS_CODE) = 0
		THEN
            V_ERR_FLG := CONST_FLAG.C_TRUE;
			V_ERR_MSG := '商品マスタ索引エラー'
						|| '	レコード番号＝' || V_IN_COUNT
						|| '	品目コード＝'   || R_TR_PROD_INV_COST_ACT_WK.PARENT_GOODS_CODE;
			CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_ERR_MSG);
		END IF;

		IF SUBSTR(R_TR_PROD_INV_COST_ACT_WK.PARENT_GOODS_CODE, 0, 3) <> SUBSTR(P_TOP_DEPT_NO, 0, 3) THEN
			-- エラーフラグ
            V_ERR_FLG := CONST_FLAG.C_TRUE;
			V_ERR_MSG := '商品コード（先頭３ケタ）アンマッチエラー。' 						  ||
						'レコード番号＝['		||	V_IN_COUNT									|| ']' ||
						'商品コード＝['		 ||	R_TR_PROD_INV_COST_ACT_WK.PARENT_GOODS_CODE	 || ']' ||
						'最上位部門番号＝['	   || P_TOP_DEPT_NO				   				   || ']';
			CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_ERR_MSG);
		END IF;
		-- ⑤ 品目仕訳区分チェック
		 BEGIN
                R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(
                            CONST_CMNNO.C_GOODS_JNL_TYPE,
                            R_TR_PROD_INV_COST_ACT_WK.GOODS_JNL_TYPE);
            EXCEPTION
                WHEN OTHERS THEN	
                    V_ERR_MSG := '区分マスタ索引エラー。' 											  ||
                    			'レコード番号＝['        || V_IN_COUNT                               || ']' ||
                   				'品目仕訳区分＝['    	  || R_TR_PROD_INV_COST_ACT_WK.GOODS_JNL_TYPE || ']';
                    CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_ERR_MSG);
                    V_ERR_FLG :=  CONST_FLAG.C_TRUE;
            END;

		-- （４） チェック判定を行う。
		IF V_ERR_FLG = CONST_FLAG.C_TRUE THEN
			V_ERR_COUNT := V_ERR_COUNT + 1;
		END IF;
	END LOOP;

	-- 3 後処理
	-- （１） 情報ログを出力する
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '製品在庫表原価実績　　　　　　読込件数: ' ||
        TO_CHAR(V_IN_COUNT,  '999,999')     || ' 件');
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '製品在庫表原価実績　　　　　エラー件数: ' ||
        TO_CHAR(V_ERR_COUNT,  '999,999')    || ' 件');

	-- （２） エラー件数 ≠0 なら、エラーメッセージを出力する。
	IF V_ERR_COUNT <> 0 THEN
        ROLLBACK;
		-- プログラム異常終了情報をログに出力
		V_ERR_MSG := '製品在庫表原価実績データエラーチェックにてエラーが発生しています。';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						NULL, NULL, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
        -- 上記メッセージ出力後、終了処理する。
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
    ELSE
        COMMIT;
        CMN.INFO(V_JOB_ID
				,C_PACKAGE_NAME
				,C_INFOLOG_NAME || 'が正常終了しました。');
	END IF;

	-- 後処理
	CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);

    RETURN V_END_CODE;

	EXCEPTION
		WHEN OTHERS THEN
            ROLLBACK;
            -- 異常終了コードをセット
            V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
            -- プログラム異常終了情報をログに出力
            V_ERR_MSG := '予期せぬエラーが発生しました。';
            CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                            C_PACKAGE_NAME, C_PROC_NAME,
                            SQLCODE, SQLERRM, V_ERR_MSG);

            V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
            CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
END CHECK_IN_PROCESS_COST_ACT;

-- *************************************************************************
--  取引先基本マスタ索引
--  @PARAM      I_COUNT		     1.読込件数
--  @PARAM      I_PARTNER_NO     2.取引先番号
--  @RETURN     件数
-- *************************************************************************
 FUNCTION GET_PARTNER(
	I_COUNT						IN	NUMBER
	,I_PARTNER_NO				IN	PARTNER_BASE_MAST.PARTNER_NO%TYPE
) RETURN NUMBER
IS
    C_PROC_NAME   CONSTANT VARCHAR2(30) := 'GET_PARTNER';
    V_MSG         VARCHAR2(4000);

	--取引先件数
	V_COUNT		NUMBER(11,0);


BEGIN
	V_COUNT	:=	0;

    SELECT  COUNT(*)
       INTO V_COUNT
    FROM 	PARTNER_BASE_MAST
    WHERE 	PARTNER_NO = I_PARTNER_NO;

	IF V_COUNT = 0 THEN
        V_MSG := '取引先基本マスタ索引エラー。'     ||
        ' レコード番号=['   || I_COUNT      || ']'  ||
        ' 仕入先番号=['     || I_PARTNER_NO || ']';

		-- ログ出力
        CMN.ERROR(V_JOB_ID,C_PACKAGE_NAME ,NULL,V_MSG);
	END IF;

	RETURN V_COUNT;

EXCEPTION
    WHEN OTHERS THEN
        -- プログラム異常終了情報をログに出力
        V_MSG := '取引先基本マスタ索引エラー。' ||
        ' 仕入先番号=[' || I_PARTNER_NO         || ']';
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);
END GET_PARTNER;
-- *************************************************************************
--  V部門基本マスタを索引
--  @PARAM      I_COUNT              1.読込件数
--  @PARAM      I_DEPT_NO		     2.部門番号
--  @PARAM      I_PARAM_NAME         3.PARAM NAME TO DISPLAY ERROR LOG
--  @RETURN     件数
-- *************************************************************************
FUNCTION GET_V_DEPT_BASE_MAST(
    I_COUNT         IN	NUMBER                              --読込件数
    ,I_DEPT_NO      IN  V_DEPT_BASE_MAST.DEPT_NO%TYPE       --部門番号
    ,I_PARAM_NAME   IN  VARCHAR2                            --
) RETURN NUMBER
IS
    C_PROC_NAME   CONSTANT VARCHAR2(30) := 'GET_V_DEPT_BASE_MAST';
    V_MSG         VARCHAR2(4000);

	--取引先件数
	V_COUNT		NUMBER(11,0);

BEGIN
    V_COUNT := 0;

    SELECT COUNT(*)
      INTO V_COUNT
      FROM V_DEPT_BASE_MAST
     WHERE DEPT_NO = I_DEPT_NO;

    IF V_COUNT = 0 THEN
        V_MSG := '部門基本マスタ索引エラー。'  ||
        ' レコード番号＝['                     || I_COUNT        || ']' ||
        ' ' || I_PARAM_NAME     || '＝['       || I_DEPT_NO      || ']';

		-- ログ出力
        CMN.ERROR(V_JOB_ID,C_PACKAGE_NAME ,NULL,V_MSG);
	END IF;

	RETURN V_COUNT;

EXCEPTION
    WHEN OTHERS THEN
        -- プログラム異常終了情報をログに出力
        V_MSG := '部門基本マスタ索引エラー。'    ||
                ' ' || I_PARAM_NAME || '＝['     || I_DEPT_NO      || ']';
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);

END GET_V_DEPT_BASE_MAST;

-- *************************************************************************
--  社員基本マスタ索引
--  @PARAM      I_COUNT              1.読込件数
--  @PARAM      I_EMP_CODE		     2.社員番号
--  @RETURN     件数
-- *************************************************************************
FUNCTION GET_EMP_BASE_MAST(
    I_COUNT					    IN	NUMBER                           --読込件数
    ,I_EMP_CODE                 IN  EMP_BASE_MAST.EMP_CODE%TYPE     --社員番号
) RETURN NUMBER
IS
    C_PROC_NAME   CONSTANT VARCHAR2(30) := 'GET_EMP_BASE_MAST';
    V_MSG         VARCHAR2(4000);

	--取引先件数
	V_COUNT		NUMBER(11,0);

BEGIN
    V_COUNT := 0;

    SELECT  COUNT(*)
       INTO V_COUNT
    FROM    EMP_BASE_MAST
    WHERE   EMP_CODE = I_EMP_CODE;

    IF V_COUNT = 0 THEN
        V_MSG := '社員基本マスタ索引エラー。'       ||
        ' レコード番号＝['          || I_COUNT      || ']' ||
        ' 仕入担当社員コード=['     || I_EMP_CODE   || ']';
		-- ログ出力
        CMN.ERROR(V_JOB_ID,C_PACKAGE_NAME ,NULL,V_MSG);
	END IF;

	RETURN V_COUNT;

EXCEPTION
    WHEN OTHERS THEN
        -- プログラム異常終了情報をログに出力
        V_MSG := '社員基本マスタ索引エラー。' ||
        ' 仕入担当社員コード=[' || I_EMP_CODE || ']';
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);

END GET_EMP_BASE_MAST;


-- *************************************************************************
--取引先属性（仕入先・諸掛先）索引する
--  @PARAM      I_COUNT                     1.読込件数
--  @PARAM      I_PARTNER_NO		        2.取引先番号
--  @PARAM      I_PARTNER_ACCOUNT_NO        3.取引先口座番号
--  @RETURN     O_R_PARTNER_ATTRIBUTE_MAST	4.取引先属性マスタ
-- *************************************************************************
PROCEDURE GET_PARTNER_ATTRIBUTE_MAST(
	 I_COUNT					IN	NUMBER
	,I_PARTNER_NO				IN	PARTNER_ATTRIBUTE_MAST.PARTNER_NO%TYPE
    ,I_PARTNER_ACCOUNT_NO       IN  PARTNER_ATTRIBUTE_MAST.PARTNER_ACCOUNT_NO%TYPE
	,O_R_PARTNER_ATTRIBUTE_MAST	OUT NOCOPY	PARTNER_ATTRIBUTE_MAST%ROWTYPE
)
IS
    C_PROC_NAME   CONSTANT VARCHAR2(30) := 'GET_PARTNER_ATTRIBUTE_MAST';
    V_MSG         VARCHAR2(4000);

	--取引先属性マスタ情報
	R_PARTNER_ATTRIBUTE_MAST			PARTNER_ATTRIBUTE_MAST%ROWTYPE;
BEGIN

	--初期化
	R_PARTNER_ATTRIBUTE_MAST := NULL;
	O_R_PARTNER_ATTRIBUTE_MAST := NULL;

	--仕入先属性マスタ情報を取得する
	BEGIN
		DM_PARTNER_ATTRIBUTE_MAST.GET_BY_LK(
			I_PARTNER_NO,
			I_PARTNER_ACCOUNT_NO,
			CONST_PGM_CMN.C_PARTNER_ATTR_TYPE_SUPPLIER,
			R_PARTNER_ATTRIBUTE_MAST);
	EXCEPTION
		WHEN OTHERS THEN
			R_PARTNER_ATTRIBUTE_MAST := NULL;
	END;

	--仕入先属性マスタを取得できなかった場合、
	--諸掛先属性マスタ情報を取得する
	IF	R_PARTNER_ATTRIBUTE_MAST.PARTNER_ATTRIBUTE_ID IS NULL	THEN
		BEGIN
			DM_PARTNER_ATTRIBUTE_MAST.GET_BY_LK(
				I_PARTNER_NO,
				I_PARTNER_ACCOUNT_NO,
				CONST_PGM_CMN.C_PARTNER_ATTR_TYPE_CHARGE,
				R_PARTNER_ATTRIBUTE_MAST);
		EXCEPTION
			WHEN OTHERS THEN
				R_PARTNER_ATTRIBUTE_MAST := NULL;
		END;
	END IF;

	IF	R_PARTNER_ATTRIBUTE_MAST.PARTNER_ATTRIBUTE_ID IS NULL	THEN
        V_MSG := '取引先属性（仕入先・諸掛先）索引エラー。' ||
        ' レコード番号＝['  || I_COUNT              || ']'  ||
        ' 取引先番号=['     || I_PARTNER_NO         || ']'  ||
        ' 取引先口座番号=[' || I_PARTNER_ACCOUNT_NO || ']';
		-- ログ出力
        CMN.ERROR(V_JOB_ID,C_PACKAGE_NAME ,NULL,V_MSG);
	END IF;

	--アウトパラメータに取得データを設定
	O_R_PARTNER_ATTRIBUTE_MAST := R_PARTNER_ATTRIBUTE_MAST;

EXCEPTION
    WHEN OTHERS THEN
        -- プログラム異常終了情報をログに出力
        V_MSG := '取引先属性（仕入先・諸掛先）索引エラー。' ||
        ' 取引先番号=['     || I_PARTNER_NO         || ']' ||
        ' 取引先口座番号=[' || I_PARTNER_ACCOUNT_NO || ']';
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);

END GET_PARTNER_ATTRIBUTE_MAST;

-- *************************************************************************
--  取引先属性（支払先）索引
--  @PARAM      I_COUNT                     1.読込件数
--  @PARAM      I_PARTNER_NO		        2.取引先番号
--  @PARAM      I_PARTNER_ACCOUNT_NO        3.取引先口座番号
--  @RETURN     件数
-- *************************************************************************
FUNCTION GET_PAY_TO(
	I_COUNT						IN	NUMBER
	,I_PARTNER_NO				IN	PARTNER_ATTRIBUTE_MAST.PARTNER_NO%TYPE
    ,I_PARTNER_ACCOUNT_NO       IN  PARTNER_ATTRIBUTE_MAST.PARTNER_ACCOUNT_NO%TYPE
) RETURN NUMBER
IS
    C_PROC_NAME   CONSTANT VARCHAR2(30) := 'GET_PAY_TO';
    V_MSG         VARCHAR2(4000);

	--取引先件数
	V_COUNT		NUMBER(11,0);

BEGIN
    V_COUNT := 0;

    SELECT COUNT(*)
      INTO V_COUNT
      FROM PARTNER_ATTRIBUTE_MAST
     WHERE PARTNER_NO               = I_PARTNER_NO
       AND PARTNER_ACCOUNT_NO       = I_PARTNER_ACCOUNT_NO
       AND PARTNER_ATTRIBUTE_TYPE   = CONST_PGM_CMN.C_PARTNER_ATTR_TYPE_PAY;

    IF V_COUNT = 0 THEN
        V_MSG := '取引先属性（支払先）索引エラー。' ||
        ' レコード番号＝['  || I_COUNT              || ']'  ||
        ' 支払先番号=['     || I_PARTNER_NO         || ']'  ||
        ' 支払先口座番号=[' || I_PARTNER_ACCOUNT_NO || ']';
		-- ログ出力
        CMN.ERROR(V_JOB_ID,C_PACKAGE_NAME ,NULL,V_MSG);
	END IF;

	RETURN V_COUNT;

EXCEPTION
    WHEN OTHERS THEN
        -- プログラム異常終了情報をログに出力
        V_MSG := '取引先属性（支払先）索引エラー。' ||
        ' 取引先番号=['     || I_PARTNER_NO         || ']' ||
        ' 取引先口座番号=[' || I_PARTNER_ACCOUNT_NO || ']';
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);
END GET_PAY_TO;

-- *************************************************************************
--  ＥＤＩコード区分変換(商社)を索引
--  @PARAM      I_COUNT                     1.読込件数
--  @PARAM      I_TOP_DEPT_NO		        2.最上位部門番号
--  @PARAM      I_EDI_DISTINCTION_TYPE      3.ＥＤＩ連携先識別区分
--  @PARAM      I_COMMON_NO                 4.共通番号
--  @PARAM      I_CODE_TYPE_NO              5.コード区分番号
--  @PARAM      I_OPER_START_DATE           6.運用開始日付
--  @PARAM      I_PARAM_NAME                7.PARAM NAME TO DISPLAY ERROR LOG
--  @RETURN     ＥＤＩコード区分変換(商社)
-- *************************************************************************
FUNCTION GET_EDI_CODE_TYPE_CONV(
    I_COUNT                     IN NUMBER
    ,I_TOP_DEPT_NO              IN TR_EDI_CODE_TYPE_CONV.TOP_DEPT_NO%TYPE
    ,I_EDI_DISTINCTION_TYPE     IN TR_EDI_CODE_TYPE_CONV.EDI_DISTINCTION_TYPE%TYPE
    ,I_COMMON_NO                IN TR_EDI_CODE_TYPE_CONV.COMMON_NO%TYPE
    ,I_CODE_TYPE_NO             IN TR_EDI_CODE_TYPE_CONV.CODE_TYPE_NO%TYPE
    ,I_OPER_START_DATE          IN TR_EDI_CODE_TYPE_CONV.OPER_START_DATE%TYPE
    ,I_PARAM_NAME               IN VARCHAR2
)RETURN TR_EDI_CODE_TYPE_CONV%ROWTYPE
IS
    C_PROC_NAME   CONSTANT VARCHAR2(30) := 'GET_EDI_CODE_TYPE_CONV';
    V_MSG         VARCHAR2(4000);

	--ＥＤＩコード区分変換
	R_EDI_CODE_TYPE_CONV		TR_EDI_CODE_TYPE_CONV%ROWTYPE;

BEGIN
    R_EDI_CODE_TYPE_CONV := NULL;

    SELECT  *
        INTO R_EDI_CODE_TYPE_CONV
    FROM        TR_EDI_CODE_TYPE_CONV
    WHERE       EDI_DISTINCTION_TYPE    =   I_EDI_DISTINCTION_TYPE
    AND         TOP_DEPT_NO             =   I_TOP_DEPT_NO
    AND         COMMON_NO               =   I_COMMON_NO
    AND         CODE_TYPE_NO            =   I_CODE_TYPE_NO
    AND         OPER_START_DATE         =  (
                SELECT  MAX(OPER_START_DATE)
                FROM        TR_EDI_CODE_TYPE_CONV
                WHERE       EDI_DISTINCTION_TYPE    =   I_EDI_DISTINCTION_TYPE
                AND         TOP_DEPT_NO             =   I_TOP_DEPT_NO
                AND         COMMON_NO               =   I_COMMON_NO
                AND         CODE_TYPE_NO            =   I_CODE_TYPE_NO
                AND         OPER_START_DATE         <=  I_OPER_START_DATE
    );

	RETURN R_EDI_CODE_TYPE_CONV;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        V_MSG := 'ＥＤＩコード区分変換(商社)を索引エラー。' ||
        ' レコード番号＝['      || I_COUNT          || '] ' ||
        I_PARAM_NAME || '=['    || I_CODE_TYPE_NO   || ']';

		-- ログ出力
        CMN.ERROR(V_JOB_ID,C_PACKAGE_NAME ,NULL,V_MSG);

    WHEN OTHERS THEN
        -- プログラム異常終了情報をログに出力
        V_MSG := 'ＥＤＩコード区分変換(商社)を索引エラー。 '    ||
        I_PARAM_NAME || '=[' || I_CODE_TYPE_NO                  || ']';
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);
END GET_EDI_CODE_TYPE_CONV;

-- *************************************************************************
--  会計年月チェック
--  @PARAM      I_COUNT                     1.読込件数
--  @PARAM      I_FINAN_YM		            2.会計年月
--  @PARAM      I_CHECKED_YM                3.ＭＣ会計年月
--  @PARAM      I_PARAM_NAME                4.PARAM NAME TO DISPLAY ERROR LOG
--  @PARAM      I_O_ERR_FLG                 5.エラーフラグ
-- *************************************************************************
PROCEDURE CHECK_FINAN_YM(
    I_COUNT         IN               NUMBER
    ,I_FINAN_YM     IN               VARCHAR2
    ,I_CHECKED_YM   IN               VARCHAR2
    ,I_PARAM_NAME   IN               VARCHAR2
    ,I_O_ERR_FLG    IN OUT NOCOPY   VARCHAR2
)
IS
    C_PROC_NAME   CONSTANT VARCHAR2(30) := 'CHECK_FINAN_YM';
    V_MSG         VARCHAR2(4000);
BEGIN
    IF I_FINAN_YM > I_CHECKED_YM THEN
        -- エラーフラグ
        I_O_ERR_FLG := CONST_FLAG.C_TRUE;
        -- エラーメッセージ出力
        V_MSG := '会計年月エラー。'    ||
        ' レコード番号＝['             || I_COUNT       || ']' ||
        ' Ｌ２会計年月＝['             || I_FINAN_YM    || ']' ||
        ' ' || I_PARAM_NAME || '＝['   || I_CHECKED_YM  || ']';
        CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
         -- プログラム異常終了情報をログに出力
        V_MSG := '会計年月エラー。'         ||
        ' Ｌ２会計年月＝['             || I_FINAN_YM    || ']' ||
        ' ' || I_PARAM_NAME || '＝['   || I_CHECKED_YM  || ']';
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);
END CHECK_FINAN_YM;

-- *************************************************************************
--  在庫種類区分チェック
--  @PARAM      I_COUNT                     1.読込件数
--  @PARAM      I_INVENT_KIND_TYPE          2.在庫種類区分
--  @PARAM      I_O_ERR_FLG                 3.エラーフラグ
-- *************************************************************************
PROCEDURE CHECK_INVENT_KIND_TYPE(
    I_COUNT                 IN              NUMBER
    ,I_INVENT_KIND_TYPE     IN              VARCHAR2
    ,I_O_ERR_FLG            IN OUT NOCOPY  VARCHAR2
)
IS
    C_PROC_NAME   CONSTANT VARCHAR2(30) := 'CHECK_INVENT_KIND_TYPE';
    V_MSG         VARCHAR2(4000);
BEGIN
    IF I_INVENT_KIND_TYPE <> CONST_PGM_CMN.C_INVENT_SORT_TYPE_MATERIAL          -- 0001
        AND I_INVENT_KIND_TYPE <> CONST_PGM_CMN.C_INVENT_SORT_TYPE_STORED THEN  -- 0002
        -- エラーフラグ
        I_O_ERR_FLG := CONST_FLAG.C_TRUE;
        -- エラーメッセージ出力
        V_MSG := '在庫種類区分対象外エラー。'       ||
        ' レコード番号＝[' || I_COUNT               || ']' ||
        ' 在庫種類区分＝[' || I_INVENT_KIND_TYPE    || ']';
        CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
         -- プログラム異常終了情報をログに出力
        V_MSG := '在庫種類区分対象外エラー。'       ||
        ' 在庫種類区分＝[' || I_INVENT_KIND_TYPE    || ']';
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);
END CHECK_INVENT_KIND_TYPE;

-- *************************************************************************
--  在庫仕訳種別チェック
--  @PARAM      I_COUNT                     1.読込件数
--  @PARAM      I_JNL_INVENT_KIND_TYPE      2.在庫仕訳種別区分
--  @PARAM      I_O_ERR_FLG                 3.エラーフラグ
-- *************************************************************************
PROCEDURE CHECK_INVENT_JNL_KIND_TYPE(
    I_COUNT                 IN              NUMBER
    ,I_JNL_INVENT_KIND_TYPE IN              VARCHAR2
    ,I_O_ERR_FLG            IN OUT NOCOPY   VARCHAR2
)
IS
    C_PROC_NAME   CONSTANT VARCHAR2(30) := 'CHECK_INVENT_JNL_KIND_TYPE';
    V_MSG         VARCHAR2(4000);
BEGIN
    IF  I_JNL_INVENT_KIND_TYPE <> CONST_PGM_CMN.C_INVENT_JOURNAL_TYPE_PREV          -- 0001
    AND I_JNL_INVENT_KIND_TYPE <> CONST_PGM_CMN.C_INVENT_JOURNAL_TYPE_PRES THEN     -- 0002
        -- エラーフラグ
        I_O_ERR_FLG := CONST_FLAG.C_TRUE;
        -- エラーメッセージ出力
        V_MSG :='区分マスタ索引エラー。'                    ||
        ' レコード番号＝['      || I_COUNT                  || ']' ||
        ' 在庫仕訳種別区分＝['  || I_JNL_INVENT_KIND_TYPE   || ']';
        CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
         -- プログラム異常終了情報をログに出力
        V_MSG :='区分マスタ索引エラー。'                    ||
        ' 在庫仕訳種別区分＝['  || I_JNL_INVENT_KIND_TYPE   || ']';
        CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, SQLERRM, V_MSG);
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);
END CHECK_INVENT_JNL_KIND_TYPE;

-- *************************************************************************
--  商品マスタを索引
--  @PARAM      I_COUNT              1.読込件数
--  @PARAM      I_GOODS_CODE		 2.部門番号
--  @RETURN     件数
-- *************************************************************************
FUNCTION GET_GOODS_MAST(

    I_COUNT                 IN              NUMBER
    ,I_GOODS_CODE           IN              VARCHAR2
)RETURN NUMBER
IS
    C_PROC_NAME   CONSTANT VARCHAR2(30) := 'GET_GOODS_MAST';
    V_MSG         VARCHAR2(4000);

	--取引先件数
	V_COUNT		NUMBER(11,0);

BEGIN
    V_COUNT := 0;

    SELECT COUNT(*)
        INTO V_COUNT
    FROM GOODS_MAST
    WHERE GOODS_CODE = I_GOODS_CODE;

    IF V_COUNT = 0 THEN
        V_MSG := '商品マスタ索引エラー。'          ||
        ' レコード番号＝['     || I_COUNT          || ']' ||
        ' 商品コード＝['       || I_GOODS_CODE     || ']';

		-- ログ出力
        CMN.ERROR(V_JOB_ID,C_PACKAGE_NAME ,NULL,V_MSG);
	END IF;

	RETURN V_COUNT;

EXCEPTION
    WHEN OTHERS THEN
        -- プログラム異常終了情報をログに出力
        V_MSG := '商品マスタ索引エラー。' ||
        ' 商品コード=[' || I_GOODS_CODE || ']';
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);

END GET_GOODS_MAST;

-- *************************************************************************
--  倉庫マスタを索引
--  @PARAM      I_COUNT              1.読込件数
--  @PARAM      I_TOP_DEPT_NO		 2.最上位部門番号
--  @PARAM      I_WAREHOUSE_NO       3.倉庫番号
--  @PARAM      I_PLACE_CODE         4.ＭＣ場所コード
--  @RETURN     件数
-- *************************************************************************
FUNCTION GET_WAREHOUSE(
    I_COUNT                 IN              NUMBER
    ,I_TOP_DEPT_NO          IN              VARCHAR2
    ,I_WAREHOUSE_NO         IN              VARCHAR2
    ,I_PLACE_CODE           IN              VARCHAR2
    ,I_PARAM_NAME           IN              VARCHAR2

)RETURN NUMBER
IS
    C_PROC_NAME   CONSTANT VARCHAR2(30) := 'GET_WAREHOUSE';
    V_MSG         VARCHAR2(4000);

	--取引先件数
	V_COUNT		NUMBER(11,0);

BEGIN
    V_COUNT := 0;

     SELECT COUNT(*)
       INTO V_COUNT
       FROM WAREHOUSE_MAST
      WHERE TOP_DEPT_NO     = I_TOP_DEPT_NO
        AND WAREHOUSE_NO    = I_WAREHOUSE_NO;


    IF V_COUNT = 0 THEN
        V_MSG := '倉庫マスタ索引エラー。'          ||
        ' レコード番号＝['     || I_COUNT          || ']' ||
        ' ' || I_PARAM_NAME    || '＝['            || I_PLACE_CODE     || ']' ||
        ' 倉庫番号＝['         || I_WAREHOUSE_NO   || ']'  ;

		-- ログ出力
        CMN.ERROR(V_JOB_ID,C_PACKAGE_NAME ,NULL,V_MSG);
	END IF;

	RETURN V_COUNT;

EXCEPTION
    WHEN OTHERS THEN
        -- プログラム異常終了情報をログに出力
        V_MSG := '倉庫マスタ索引エラー。'          ||
        ' ' || I_PARAM_NAME    || '＝['            || I_PLACE_CODE     || ']' ||
        ' 倉庫番号＝['         || I_WAREHOUSE_NO   || ']'  ;
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);
END GET_WAREHOUSE;


-- *************************************************************************
--  在庫置場マスタを索引
--  @PARAM      I_COUNT              1.読込件数
--  @PARAM      I_TOP_DEPT_NO         2.最上位部門番号
--  @PARAM      I_WAREHOUSE_NO       3.倉庫番号
--  @PARAM      I_INVENT_PLACE_NO    4.在庫置き場番号
--  @PARAM      I_PLACE_CODE         5.ＭＣ場所コード
--  @RETURN     件数
-- *************************************************************************
FUNCTION GET_INVENT_PLACE(
    I_COUNT                 IN              NUMBER
    ,I_TOP_DEPT_NO          IN              VARCHAR2
    ,I_WAREHOUSE_NO         IN              VARCHAR2
    ,I_INVENT_PLACE_NO      IN              VARCHAR2
    ,I_PLACE_CODE           IN              VARCHAR2
    ,I_PARAM_NAME           IN              VARCHAR2
)RETURN NUMBER
IS
    C_PROC_NAME   CONSTANT VARCHAR2(30) := 'GET_INVENT_PLACE';
    V_MSG         VARCHAR2(4000);

    --取引先件数
    V_COUNT        NUMBER(11,0);

BEGIN
    V_COUNT := 0;

     SELECT COUNT(*)
       INTO V_COUNT
       FROM INVENT_PLACE_MAST
      WHERE TOP_DEPT_NO     = I_TOP_DEPT_NO
        AND WAREHOUSE_NO    = I_WAREHOUSE_NO
        AND INVENT_PLACE_NO = I_INVENT_PLACE_NO;


    IF V_COUNT = 0 THEN
        V_MSG := '在庫置場マスタ索引エラー。'          ||
        ' レコード番号＝['     || I_COUNT          || ']' ||
        ' ' || I_PARAM_NAME    ||'＝['             || I_PLACE_CODE     || ']' ||
        ' 倉庫番号＝['         || I_WAREHOUSE_NO   || ']' ||
        ' 置場番号＝['         || I_INVENT_PLACE_NO|| ']' ;

        -- ログ出力
        CMN.ERROR(V_JOB_ID,C_PACKAGE_NAME ,NULL,V_MSG);
    END IF;

    RETURN V_COUNT;

EXCEPTION
    WHEN OTHERS THEN
        -- プログラム異常終了情報をログに出力
        V_MSG := '在庫置場マスタ索引エラー。'          ||
        ' ' || I_PARAM_NAME    ||'＝['             || I_PLACE_CODE     || ']' ||
        ' 倉庫番号＝['         || I_WAREHOUSE_NO   || ']' ||
        ' 置場番号＝['         || I_INVENT_PLACE_NO|| ']' ;
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);
END GET_INVENT_PLACE;

-- *************************************************************************
--  年度チェック
--  @PARAM      I_COUNT                 1.読込件数
--  @PARAM      I_FINAN_YEAR            2.会計年度
--  @PARAM      I_CHECKED_FINAN_YEAR    3.会計年度
--  @PARAM      I_O_ERR_FLG             4.エラーフラグ
-- *************************************************************************
PROCEDURE CHECK_FINAN_YEAR(
    I_COUNT                 IN                  VARCHAR2
    ,I_FINAN_YEAR           IN                  VARCHAR2
    ,I_CHECKED_FINAN_YEAR   IN                  VARCHAR2
    ,I_O_ERR_FLG            IN OUT NOCOPY      VARCHAR2
)IS
    C_PROC_NAME   CONSTANT VARCHAR2(30) := 'CHECK_FINAN_YEAR';
    V_MSG         VARCHAR2(4000);
BEGIN
    IF I_FINAN_YEAR > I_CHECKED_FINAN_YEAR THEN
        -- エラーフラグ
        I_O_ERR_FLG := CONST_FLAG.C_TRUE;
        -- エラーメッセージ出力
        V_MSG := '年度エラー。'    ||
        ' レコード番号＝['         || I_COUNT                || ']' ||
        ' Ｌ２年度＝['             || I_FINAN_YEAR           || ']' ||
        ' ＭＣ年度＝['             || I_CHECKED_FINAN_YEAR   || ']';
        CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
         -- プログラム異常終了情報をログに出力
        V_MSG := '年度エラー。'         ||
        ' Ｌ２年度＝['             || I_FINAN_YEAR           || ']' ||
        ' ＭＣ年度＝['             || I_CHECKED_FINAN_YEAR   || ']';
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);
END CHECK_FINAN_YEAR;

-- *************************************************************************
--  在庫計算方法区分チェック
--  @PARAM      I_COUNT                 1.読込件数
--  @PARAM      I_INVENT_CALC_TYPE      2.在庫系残方法区分
--  @PARAM      I_O_ERR_FLG             3.エラーフラグ
-- *************************************************************************
PROCEDURE CHECK_INVENT_CALC_TYPE(
    I_COUNT                 IN                  VARCHAR2
    ,I_INVENT_CALC_TYPE     IN                  VARCHAR2
    ,I_O_ERR_FLG            IN OUT NOCOPY      VARCHAR2
)
IS
    C_PROC_NAME   CONSTANT VARCHAR2(30) := 'CHECK_INVENT_CALC_TYPE';
    V_MSG         VARCHAR2(4000);
BEGIN
    IF I_INVENT_CALC_TYPE <> CONST_PGM_CMN.C_INVENT_CALC_MONTHLY_AVG
        AND I_INVENT_CALC_TYPE <> CONST_PGM_CMN.C_INVENT_CALC_PERIODIC_AVG THEN
        -- エラーフラグ
        I_O_ERR_FLG := CONST_FLAG.C_TRUE;
        -- エラーメッセージ出力
        V_MSG := '在庫計算方法対象外エラー。'    ||
        ' レコード番号＝['                 || I_COUNT              || ']' ||
        ' 在庫計算方法区分＝['             || I_INVENT_CALC_TYPE   || ']';
        CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
         -- プログラム異常終了情報をログに出力
        V_MSG := '在庫計算方法対象外エラー。'         ||
        ' 在庫計算方法区分＝['             || I_INVENT_CALC_TYPE    || ']';
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);
END CHECK_INVENT_CALC_TYPE;

END "TR_MC_DATA_ERROR_CHECK";
