CREATE OR REPLACE PACKAGE BODY "TR_MC_DATA_ERROR_CHECK" AS
-- *****************************************************************************
--		$Id: PACKAGE.BODY.TR_MC_DATA_ERROR_CHECK.pls 11120 2013-08-30 02:19:08Z trangnt $
--		�ڋq��				�F�O�J�Y�Ɗ������
--		�V�X�e����			�F�k�Q�v���W�F�N�g
--		�T�u�V�X�e����			�F190 ���Y�Ǘ�
--		�Ǝ햼�i���ƕ����j	    �F���̌^�@�O���[�v���
--		All rights reserved, Copyright (c) MITANI SANGYO Co.,Ltd. 2008-
-- *****************************************************************************

	-- �p�b�P�[�W����
	C_PROGRAM_NAME	CONSTANT	VARCHAR2(100)	:= '���Y�Ǘ��f�[�^�G���[�`�F�b�N';
	C_PACKAGE_NAME	CONSTANT	VARCHAR2(30)	:= 'TR_MC_DATA_ERROR_CHECK';

	LOGICAL_ERROR	EXCEPTION;              -- �_���G���[
	EXPECTED_ERROR	EXCEPTION;              -- �\�������G���[

	P_TOP_DEPT_NO				 VARCHAR2(20);		-- 1.�ŏ�ʕ���ԍ��i�K�{�j

	-- �萔
	-- ���̑��L��ϐ�
	V_JOB_ID                    NUMBER := NULL;         -- �W���uID
	V_WARN_CNT		            NUMBER := 0;            -- �x����������
	V_END_CODE                  NUMBER;                 -- �I���R�[�h

	-- �V�X�e�����t�ޔ�
    V_SYSDATE					DATE;

-- *****************************************************************************
--    �T�u�v���O�����錾
-- *****************************************************************************
-- ������{�}�X�^����
FUNCTION GET_PARTNER(
	I_COUNT						IN	NUMBER
	,I_PARTNER_NO				IN	PARTNER_BASE_MAST.PARTNER_NO%TYPE
) RETURN NUMBER;

-- V�����{�}�X�^����������B
FUNCTION GET_V_DEPT_BASE_MAST(
    I_COUNT                     IN	    NUMBER
    ,I_DEPT_NO                  IN      V_DEPT_BASE_MAST.DEPT_NO%TYPE
    ,I_PARAM_NAME               IN      VARCHAR2
) RETURN NUMBER;

-- �Ј���{�}�X�^����������B
FUNCTION GET_EMP_BASE_MAST(
    I_COUNT                  IN NUMBER
    ,I_EMP_CODE              IN EMP_BASE_MAST.EMP_CODE%TYPE
)RETURN NUMBER;

--����摮���i�d����E���|��j��������B
PROCEDURE GET_PARTNER_ATTRIBUTE_MAST(
	 I_COUNT					IN	NUMBER
	,I_PARTNER_NO				IN	PARTNER_ATTRIBUTE_MAST.PARTNER_NO%TYPE
    ,I_PARTNER_ACCOUNT_NO       IN  PARTNER_ATTRIBUTE_MAST.PARTNER_ACCOUNT_NO%TYPE
	,O_R_PARTNER_ATTRIBUTE_MAST	OUT NOCOPY	PARTNER_ATTRIBUTE_MAST%ROWTYPE
);

--����摮���i�x����j��������B
FUNCTION GET_PAY_TO(
	I_COUNT						IN	NUMBER
	,I_PARTNER_NO				IN	PARTNER_ATTRIBUTE_MAST.PARTNER_NO%TYPE
    ,I_PARTNER_ACCOUNT_NO       IN  PARTNER_ATTRIBUTE_MAST.PARTNER_ACCOUNT_NO%TYPE
) RETURN NUMBER;

--�d�c�h�R�[�h�敪�ϊ�(����)����������B
FUNCTION GET_EDI_CODE_TYPE_CONV(
    I_COUNT                     IN NUMBER
    ,I_TOP_DEPT_NO              IN TR_EDI_CODE_TYPE_CONV.TOP_DEPT_NO%TYPE
    ,I_EDI_DISTINCTION_TYPE     IN TR_EDI_CODE_TYPE_CONV.EDI_DISTINCTION_TYPE%TYPE
    ,I_COMMON_NO                IN TR_EDI_CODE_TYPE_CONV.COMMON_NO%TYPE
    ,I_CODE_TYPE_NO             IN TR_EDI_CODE_TYPE_CONV.CODE_TYPE_NO%TYPE
    ,I_OPER_START_DATE          IN TR_EDI_CODE_TYPE_CONV.OPER_START_DATE%TYPE
    ,I_PARAM_NAME               IN VARCHAR2
)RETURN TR_EDI_CODE_TYPE_CONV%ROWTYPE;

-- ��v�N���`�F�b�N
PROCEDURE CHECK_FINAN_YM(
    I_COUNT         IN               NUMBER
    ,I_FINAN_YM     IN               VARCHAR2
    ,I_CHECKED_YM   IN               VARCHAR2
    ,I_PARAM_NAME   IN               VARCHAR2
    ,I_O_ERR_FLG    IN OUT NOCOPY   VARCHAR2
);

-- �݌Ɏ�ދ敪�`�F�b�N
PROCEDURE CHECK_INVENT_KIND_TYPE(
    I_COUNT                 IN                  NUMBER
    ,I_INVENT_KIND_TYPE     IN                  VARCHAR2
    ,I_O_ERR_FLG            IN OUT NOCOPY      VARCHAR2
);

-- �݌Ɏd���ʃ`�F�b�N
PROCEDURE CHECK_INVENT_JNL_KIND_TYPE(
    I_COUNT                 IN                   NUMBER
    ,I_JNL_INVENT_KIND_TYPE IN                   VARCHAR2
    ,I_O_ERR_FLG            IN OUT NOCOPY       VARCHAR2
);

-- ���i�}�X�^������
FUNCTION GET_GOODS_MAST(
    I_COUNT                 IN              NUMBER
    ,I_GOODS_CODE           IN              VARCHAR2
)RETURN NUMBER;

--�q�Ƀ}�X�^������
FUNCTION GET_WAREHOUSE(
    I_COUNT                 IN              NUMBER
    ,I_TOP_DEPT_NO          IN              VARCHAR2
    ,I_WAREHOUSE_NO         IN              VARCHAR2
    ,I_PLACE_CODE           IN              VARCHAR2
    ,I_PARAM_NAME           IN              VARCHAR2
)RETURN NUMBER;

--�݌ɒu��}�X�^������
FUNCTION GET_INVENT_PLACE(
    I_COUNT                 IN              NUMBER
    ,I_TOP_DEPT_NO          IN              VARCHAR2
    ,I_WAREHOUSE_NO         IN              VARCHAR2
    ,I_INVENT_PLACE_NO      IN              VARCHAR2
    ,I_PLACE_CODE           IN              VARCHAR2
    ,I_PARAM_NAME           IN              VARCHAR2
)RETURN NUMBER;

-- �N�x�`�F�b�N
PROCEDURE CHECK_FINAN_YEAR(
    I_COUNT                 IN                  VARCHAR2
    ,I_FINAN_YEAR           IN                  VARCHAR2
    ,I_CHECKED_FINAN_YEAR   IN                  VARCHAR2
    ,I_O_ERR_FLG            IN OUT NOCOPY      VARCHAR2
);
-- �݌Ɍv�Z���@�敪�`�F�b�N
PROCEDURE CHECK_INVENT_CALC_TYPE(
    I_COUNT                 IN                  VARCHAR2
    ,I_INVENT_CALC_TYPE     IN                  VARCHAR2
    ,I_O_ERR_FLG            IN OUT NOCOPY      VARCHAR2
);

-- *****************************************************************************
--    ���C������
-- *****************************************************************************
-- *****************************************************************************
--  �v���O�������F190_20_10_02 ���ޗ������c�G���[�`�F�b�N
--  �P�D���ޗ������c�̓��e���`�F�b�N����B
--
--  @PARAM		I_JOB_ID			�W���uID
--  @PARAM		I_EXEC_JOB_ID		���s���[�UID
--  @PARAM		I_TOP_DEPT_NO		�ŏ�ʕ���ԍ�
--  @RETURN		�I���R�[�h
-- *****************************************************************************
FUNCTION CHECK_ORDER_REMAIN(
    I_JOB_ID					IN	NUMBER
	,I_EXEC_JOB_ID				IN	VARCHAR2
	,I_TOP_DEPT_NO				IN	VARCHAR2
) RETURN NUMBER
IS
	C_PROC_NAME		CONSTANT	VARCHAR2(30)
								:= 'CHECK_ORDER_REMAIN';
	-- ���O�o�͗p����
	C_INFOLOG_NAME	CONSTANT	VARCHAR2(30)
								:= '���ޗ������c�G���[�`�F�b�N';

	V_ERR_MSG					VARCHAR2(4000); -- �G���[���b�Z�[�W

    -- �����J�E���g
    V_IN_COUNT                  NUMBER;         --�Ǎ�����
    V_ERR_COUNT                 NUMBER;       	--�G���[����

	-- ���ޗ������c���擾����
	CURSOR CUR_MATERIAL_ORDER_REMAIN IS
		SELECT	    A.*
		FROM	    TR_MATERIAL_ORDER_REMAIN A
		WHERE	    A.TOP_DEPT_NO = P_TOP_DEPT_NO
		ORDER BY	A.TR_MATERIAL_ORDER_REMAIN_ID
		FOR UPDATE;

BEGIN

	-- ������
	V_END_CODE := CONST_BATCH_EXIT_CODE.C_NORMAL_EXIT;
	V_WARN_CNT := 0;			-- �x����������

	--����
	P_TOP_DEPT_NO := I_TOP_DEPT_NO;

	-- �W���uID���擾
	V_JOB_ID := CMN.PRE_PROCESS(I_JOB_ID, I_EXEC_JOB_ID, C_PACKAGE_NAME);

	-- �v���O�����J�n�������O�ɏo��
	CMN.INFO(V_JOB_ID
			,C_PACKAGE_NAME
			,C_INFOLOG_NAME || '���J�n���܂����B');

    -- �V�X�e�����t���擾
	V_SYSDATE := SYSDATE;

    -- �J�E���g�[���N���A
    V_IN_COUNT := 0;
    V_ERR_COUNT := 0;

	-- �{����

	FOR R_MATERIAL_ORDER_REMAIN IN CUR_MATERIAL_ORDER_REMAIN LOOP

        -- �Ǎ������J�E���g�A�b�v
        V_IN_COUNT := V_IN_COUNT + 1;

		-- �d����`�F�b�N
		IF	GET_PARTNER(V_IN_COUNT,R_MATERIAL_ORDER_REMAIN.SUPPLIER_NO) = 0 THEN
			--�����s��
			V_ERR_COUNT := V_ERR_COUNT + 1;

			-- �X�V
			UPDATE  TR_MATERIAL_ORDER_REMAIN
			SET     ERROR_FLG       = CONST_FLAG.C_TRUE
				    ,REG_DATE_TIME  = V_SYSDATE
			WHERE CURRENT OF CUR_MATERIAL_ORDER_REMAIN;
    	ELSE
			-- �X�V
			UPDATE  TR_MATERIAL_ORDER_REMAIN
			SET     ERROR_FLG       = CONST_FLAG.C_FALSE
				    ,REG_DATE_TIME  = V_SYSDATE
			WHERE CURRENT OF CUR_MATERIAL_ORDER_REMAIN;
		END IF;

    END LOOP;

	-- �R�~�b�g����
	COMMIT;

	-- �������O�\��
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '���ޗ������c�@�@�@�@�@�@�Ǎ�����: ' ||
        TO_CHAR(V_IN_COUNT,  '999,999')     || ' ��');
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '���ޗ������c�@�@�@�@�@�G���[����: ' ||
        TO_CHAR(V_ERR_COUNT,  '999,999')    || ' ��');

	-- ����I���������O�ɏo��
	IF V_ERR_COUNT = 0 THEN
		CMN.INFO(V_JOB_ID
				,C_PACKAGE_NAME
				,C_INFOLOG_NAME || '������I�����܂����B');
	ELSE
		V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		-- �v���O�����ُ�I���������O�ɏo��
		V_ERR_MSG := '���ޗ������c�G���[�`�F�b�N�ɂăG���[���������Ă��܂��B';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						NULL, NULL, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
	END IF;

	-- �㏈��
	CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);

    RETURN V_END_CODE;

EXCEPTION
	WHEN OTHERS THEN
		-- ���[���o�b�N
		ROLLBACK;
		-- �ُ�I���R�[�h���Z�b�g
		V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		-- �v���O�����ُ�I���������O�ɏo��
		V_ERR_MSG := '�\�����ʃG���[���������܂����B';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						SQLCODE, SQLERRM, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
END CHECK_ORDER_REMAIN;

-- *****************************************************************************
--�@�v���O������ : 190_20_11_02 �d�����уf�[�^�G���[�`�F�b�N
--  @PARAM		I_JOB_ID			�W���uID
--  @PARAM		I_EXEC_JOB_ID		���s���[�UID
--  @PARAM		I_TOP_DEPT_NO		�ŏ�ʕ���ԍ�
--  @RETURN		�I���R�[�h
-- *****************************************************************************
FUNCTION CHECK_PURCHASE_ACTUAL(
    I_JOB_ID                IN NUMBER      --�W���u�h�c
    ,I_EXEC_JOB_ID          IN VARCHAR2    --���s���[�U�[�h�c
    ,I_TOP_DEPT_NO          IN VARCHAR2    --�ŏ�ʕ���ԍ�
)RETURN NUMBER
IS

    C_PROC_NAME		CONSTANT	VARCHAR2(30)
								:= 'CHECK_PURCHASE_ACTUAL';
	-- ���O�o�͗p����
	C_INFOLOG_NAME	CONSTANT	VARCHAR2(30)
								:= '�d�����уf�[�^�G���[�`�F�b�N';

	V_MSG						            VARCHAR2(4000); -- ���b�Z�[�W
	V_ERR_MSG					            VARCHAR2(4000); -- �G���[���b�Z�[�W
    V_FINAN_YM                              VARCHAR2(6); -- ��v�N��
    R_EDI_CODE_TYPE_CONV_UNIT               TR_EDI_CODE_TYPE_CONV%ROWTYPE; --�d�c�h�R�[�h�敪�ϊ�(����) UNIT TYPE
    R_EDI_CODE_TYPE_CONV_CONSU_TAX          TR_EDI_CODE_TYPE_CONV%ROWTYPE; --�d�c�h�R�[�h�敪�ϊ�(����) CONSU TAX TAXATION TYPE
    R_EDI_CODE_TYPE_CONV_TAX_RATE           TR_EDI_CODE_TYPE_CONV%ROWTYPE; --�d�c�h�R�[�h�敪�ϊ�(����) TAX RATE TYPE
    R_TYPE_MAST                             TYPE_MAST%ROWTYPE; --�n���}�X�^���擾
    V_PARAM_NAME                            VARCHAR2(50); -- USE FOR PARAM NAME IN STEP 6, 7, 8

	--����摮���}�X�^�i�x���摮���}�X�^�擾�̂��߂Ɏg�p�j
	R_PARTNER_ATTRIBUTE_MAST				PARTNER_ATTRIBUTE_MAST%ROWTYPE;

    -- �����J�E���g
    V_IN_COUNT                  NUMBER;         --�Ǎ�����
    V_ERR_COUNT                 NUMBER;       	--�G���[����
    V_ERR_FLG                   VARCHAR2(1);    --�G���[�t���O

	-- ���o�ΏۂƂȂ�d�����у��[�N���擾����
	CURSOR CUR_TR_PURCHASE_ACT_WK IS
		SELECT      A.*
		FROM	    TR_PURCHASE_ACT_WK A
		WHERE	    A.TOP_DEPT_NO = P_TOP_DEPT_NO
		ORDER BY	A.ID
		FOR UPDATE;

BEGIN

	-- ������
	V_END_CODE := CONST_BATCH_EXIT_CODE.C_NORMAL_EXIT;
	V_WARN_CNT := 0;			-- �x����������

	--����
	P_TOP_DEPT_NO := I_TOP_DEPT_NO;

	-- (1) �W���uID���擾
	V_JOB_ID := CMN.PRE_PROCESS(I_JOB_ID, I_EXEC_JOB_ID, C_PACKAGE_NAME);

	-- (2) �v���O�����J�n�������O�ɏo��
	CMN.INFO(V_JOB_ID
			,C_PACKAGE_NAME
			,C_INFOLOG_NAME || '���J�n���܂����B');

    --�i�R�j��v�N�����擾����B
    V_FINAN_YM := CMN_OPER_ADMIN.GET_TOP_DEPT_FINAN_YM(P_TOP_DEPT_NO);

    -- �V�X�e�����t���擾
	V_SYSDATE := SYSDATE;

    -- �J�E���g�[���N���A
    V_IN_COUNT := 0;
    V_ERR_COUNT := 0;

	-- �{����

	FOR R_PURCHASE_ACT_WK IN CUR_TR_PURCHASE_ACT_WK LOOP

        -- �Ǎ������J�E���g�A�b�v
        V_IN_COUNT := V_IN_COUNT + 1;

        -- �@ �G���[�t���O
        V_ERR_FLG := CONST_FLAG.C_FALSE;

        -- �A ���呶�݃`�F�b�N
		IF	GET_V_DEPT_BASE_MAST(V_IN_COUNT, R_PURCHASE_ACT_WK.PURCHASE_DUE_DEPT_NO, '�d���S������ԍ�') = 0 THEN
            -- �G���[�t���O
            V_ERR_FLG := CONST_FLAG.C_TRUE;
		END IF;

        -- �B ����ԍ��`�F�b�N
        IF SUBSTR(R_PURCHASE_ACT_WK.PURCHASE_DUE_DEPT_NO, 0, 3)
            <> SUBSTR(P_TOP_DEPT_NO, 0, 3) THEN
            -- �G���[�t���O
            V_ERR_FLG := CONST_FLAG.C_TRUE;
            V_MSG := '����ԍ��i�擪�R�P�^�j�A���}�b�`�G���[�B'                 ||
            ' ���R�[�h�ԍ���['      || V_IN_COUNT                               || ']' ||
            ' �ŏ�ʕ���ԍ���['    || P_TOP_DEPT_NO                            || ']' ||
            ' �d���S������ԍ���['  || R_PURCHASE_ACT_WK.PURCHASE_DUE_DEPT_NO   || ']';
            CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
        END IF;

        -- �C �Ј����݃`�F�b�N
        IF R_PURCHASE_ACT_WK.PURCHASE_DUE_EMP_CODE IS NOT NULL THEN
            IF GET_EMP_BASE_MAST(V_IN_COUNT, R_PURCHASE_ACT_WK.PURCHASE_DUE_EMP_CODE) = 0 THEN
                -- �G���[�t���O
                V_ERR_FLG := CONST_FLAG.C_TRUE;
            END IF;
        END IF;

		-- �D-0
		--�d����E���|�摮�������擾����
		R_PARTNER_ATTRIBUTE_MAST := NULL;
		GET_PARTNER_ATTRIBUTE_MAST(
			V_IN_COUNT,
			R_PURCHASE_ACT_WK.SUPPLIER_NO,
			R_PURCHASE_ACT_WK.SUPPLIER_ACCOUNT_NO,
			R_PARTNER_ATTRIBUTE_MAST);
		IF	R_PARTNER_ATTRIBUTE_MAST.PARTNER_ATTRIBUTE_ID IS NULL	THEN
            -- �G���[�t���O
            V_ERR_FLG := CONST_FLAG.C_TRUE;
		END IF;


        -- �D �d���摶�݃`�F�b�N
        IF GET_PAY_TO(V_IN_COUNT, R_PARTNER_ATTRIBUTE_MAST.INVO_PAY_TO_PARTNER_NO,
                        R_PARTNER_ATTRIBUTE_MAST.INVO_PAY_TO_PARTNER_ACCOUNT_NO) = 0 THEN
            -- �G���[�t���O
            V_ERR_FLG := CONST_FLAG.C_TRUE;
        END IF;

        -- �E �l�b��P�ʂb�c�`�F�b�N
        R_EDI_CODE_TYPE_CONV_UNIT := NULL;
        V_PARAM_NAME := '�l�b��P�ʂb�c';

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
                -- �G���[�t���O
                V_ERR_FLG := CONST_FLAG.C_TRUE;

        END;
        --�敪�}�X�^������������B
        IF R_EDI_CODE_TYPE_CONV_UNIT.TR_EDI_CODE_TYPE_CONV_ID IS NOT NULL THEN
            BEGIN
                R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(
                            CONST_CMNNO.C_UNIT_TYPE,
                            R_EDI_CODE_TYPE_CONV_UNIT.CHAR_HEAD1);
            EXCEPTION
                WHEN OTHERS THEN
                    -- �G���[�t���O
                    V_ERR_FLG := CONST_FLAG.C_TRUE;

                    V_MSG := '�敪�}�X�^�����G���[�B'                               ||
                    ' ���R�[�h�ԍ���['      || V_IN_COUNT                           || ']' ||
                    ' �l�b��P�ʂb�c��['  || R_PURCHASE_ACT_WK.MC_UNIT_CD         || ']' ||
                    ' �d���P�ʋ敪��['      || R_EDI_CODE_TYPE_CONV_UNIT.CHAR_HEAD1 || ']';
                    CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
            END;
        END IF;
        -- �F �l�b�łb�c�`�F�b�N
        R_EDI_CODE_TYPE_CONV_CONSU_TAX := NULL;
        V_PARAM_NAME := '�l�b�łb�c';
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
                -- �G���[�t���O
                V_ERR_FLG := CONST_FLAG.C_TRUE;
        END;

        --�敪�}�X�^������������B
        IF R_EDI_CODE_TYPE_CONV_CONSU_TAX.TR_EDI_CODE_TYPE_CONV_ID IS NOT NULL THEN
            BEGIN
                R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(
                            CONST_CMNNO.C_CONSU_TAX_TAXATION_TYPE,
                            R_EDI_CODE_TYPE_CONV_CONSU_TAX.CHAR_HEAD1);
            EXCEPTION
                WHEN OTHERS THEN
                    -- �G���[�t���O
                    V_ERR_FLG := CONST_FLAG.C_TRUE;

                    V_MSG := '�敪�}�X�^�����G���[�B'                                          ||
                    ' ���R�[�h�ԍ���['      || V_IN_COUNT                                      || ']' ||
                    ' �l�b�łb�c��['        || R_PURCHASE_ACT_WK.MC_CTAX_CD                    || ']' ||
                    ' ����ŉېŋ敪��['    || R_EDI_CODE_TYPE_CONV_CONSU_TAX.CHAR_HEAD1       || ']';
                    CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
            END;
        END IF;

        -- �G �l�b����ŗ��`�F�b�N
        R_EDI_CODE_TYPE_CONV_TAX_RATE := NULL;
        V_PARAM_NAME := '�l�b����ŗ�';
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
                   -- �G���[�t���O
                    V_ERR_FLG := CONST_FLAG.C_TRUE;
        END;

        --�敪�}�X�^������������B
        IF R_EDI_CODE_TYPE_CONV_TAX_RATE.TR_EDI_CODE_TYPE_CONV_ID IS NOT NULL THEN
            BEGIN
                R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(
                            CONST_CMNNO.C_TAX_RATE_TYPE,
                            R_EDI_CODE_TYPE_CONV_TAX_RATE.CHAR_HEAD1);
            EXCEPTION
                WHEN OTHERS THEN
                -- �G���[�t���O
                V_ERR_FLG := CONST_FLAG.C_TRUE;

                V_MSG := '�敪�}�X�^�����G���[�B'                                  ||
                ' ���R�[�h�ԍ���['  || V_IN_COUNT                                  || ']' ||
                ' �l�b����ŗ���['  || R_PURCHASE_ACT_WK.MC_CTAX_RATE              || ']' ||
                ' �ŗ��敪��['      || R_EDI_CODE_TYPE_CONV_TAX_RATE.CHAR_HEAD1    || ']';
                CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
            END;
        END IF;

        -- �H ��v�N���`�F�b�N
        CHECK_FINAN_YM(V_IN_COUNT, V_FINAN_YM, R_PURCHASE_ACT_WK.FINAN_YM, '�l�b��v�N��', V_ERR_FLG);

        -- �I �݌Ɏ�ދ敪�`�F�b�N
        CHECK_INVENT_KIND_TYPE(V_IN_COUNT, R_PURCHASE_ACT_WK.INVENT_KIND_TYPE, V_ERR_FLG);

        -- �J �ԍ��敪�`�F�b�N
        BEGIN
            R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(
                        CONST_CMNNO.C_RED_BLACK_TYPE,
                        R_PURCHASE_ACT_WK.RED_BLACK_TYPE);
            EXCEPTION
                WHEN OTHERS THEN
                    -- �G���[�t���O
                    V_ERR_FLG := CONST_FLAG.C_TRUE;
                    V_MSG := '�敪�}�X�^�����G���[�B'                       ||
                    ' ���R�[�h�ԍ���['  || V_IN_COUNT                       || ']' ||
                    ' �ԍ��敪��['      || R_PURCHASE_ACT_WK.RED_BLACK_TYPE || ']';
                    CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
        END;

        -- �i�S�j�`�F�b�N������s���B
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

	-- �������O�\��
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '�d�����у��[�N�@�@�@�@�@�@�Ǎ�����: ' ||
        TO_CHAR(V_IN_COUNT,  '999,999')     || ' ��');
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '�d�����у��[�N�@�@�@�@�@�G���[����: ' ||
        TO_CHAR(V_ERR_COUNT,  '999,999')    || ' ��');

	-- ����I���������O�ɏo��
	IF V_ERR_COUNT = 0 THEN
        -- �R�~�b�g����
    	COMMIT;
		CMN.INFO(V_JOB_ID
				,C_PACKAGE_NAME
				,C_INFOLOG_NAME || '������I�����܂����B');
	ELSE
        -- ���[���o�b�N
        ROLLBACK;
		-- �v���O�����ُ�I���������O�ɏo��
		V_ERR_MSG := '�d�����уf�[�^�G���[�`�F�b�N�ɂăG���[���������Ă��܂��B';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						NULL, NULL, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
	END IF;

	-- �㏈��
	CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);

    RETURN V_END_CODE;

EXCEPTION
	WHEN OTHERS THEN
		-- ���[���o�b�N
		ROLLBACK;
		-- �ُ�I���R�[�h���Z�b�g
		V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		-- �v���O�����ُ�I���������O�ɏo��
		V_ERR_MSG := '�\�����ʃG���[���������܂����B';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						SQLCODE, SQLERRM, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
END CHECK_PURCHASE_ACTUAL;

-- *****************************************************************************
--�@�v���O������ : 190_20_12_02 ���ޗ��o��o�f�[�^�G���[�`�F�b�N
--  @PARAM		I_JOB_ID			�W���uID
--  @PARAM		I_EXEC_JOB_ID		���s���[�UID
--  @PARAM		I_TOP_DEPT_NO		�ŏ�ʕ���ԍ�
--  @RETURN		�I���R�[�h
-- *****************************************************************************
FUNCTION CHECK_MATERIAL_TAKE_OUT(
    I_JOB_ID                    IN NUMBER      --�W���u�h�c
    ,I_EXEC_JOB_ID              IN VARCHAR2    --���s���[�U�[�h�c
    ,I_TOP_DEPT_NO              IN VARCHAR2    --�ŏ�ʕ���ԍ�
)RETURN NUMBER
IS
    C_PROC_NAME		CONSTANT	VARCHAR2(30)
								:= 'CHECK_MATERIAL_TAKE_OUT';
	-- ���O�o�͗p����
	C_INFOLOG_NAME	CONSTANT	VARCHAR2(50)
								:= '���ޗ��o��o�f�[�^�G���[�`�F�b�N';

	V_MSG						VARCHAR2(4000); -- ���b�Z�[�W
	V_ERR_MSG					VARCHAR2(4000); -- �G���[���b�Z�[�W

    -- �����J�E���g
    V_IN_COUNT                  NUMBER;         --�Ǎ�����
    V_ERR_COUNT                 NUMBER;       	--�G���[����
    V_ERR_FLG                   VARCHAR2(1);    --�G���[�t���O

    V_FINAN_YM                  VARCHAR(6);     --��v�N��
    R_EDI_CODE_TYPE_CONV        TR_EDI_CODE_TYPE_CONV%ROWTYPE; --�d�c�h�R�[�h�敪�ϊ�(����)
    R_TYPE_MAST                 TYPE_MAST%ROWTYPE; --�敪�}�X�^���

	-- ���o�ΏۂƂȂ錴�ޗ��o��o���[�N���擾����
	CURSOR CUR_MATERIAL_WK IS
        SELECT      A.*
        FROM        TR_MATERIAL_WK A
        WHERE       A.TOP_DEPT_NO = P_TOP_DEPT_NO
        ORDER BY    A.ID
        FOR UPDATE;

BEGIN

	-- ������
	V_END_CODE := CONST_BATCH_EXIT_CODE.C_NORMAL_EXIT;
	V_WARN_CNT := 0;			-- �x����������

	--����
	P_TOP_DEPT_NO := I_TOP_DEPT_NO;

	-- (1) �W���uID���擾
	V_JOB_ID := CMN.PRE_PROCESS(I_JOB_ID, I_EXEC_JOB_ID, C_PACKAGE_NAME);

	-- (2) �v���O�����J�n�������O�ɏo��
	CMN.INFO(V_JOB_ID
			,C_PACKAGE_NAME
			,C_INFOLOG_NAME || '���J�n���܂����B');

    --�i�R�j��v�N�����擾����B
    V_FINAN_YM := CMN_OPER_ADMIN.GET_TOP_DEPT_FINAN_YM(P_TOP_DEPT_NO);

    -- �V�X�e�����t���擾
	V_SYSDATE := SYSDATE;

    -- �J�E���g�[���N���A
    V_IN_COUNT := 0;
    V_ERR_COUNT := 0;

	-- �{����

	FOR R_MATERIAL_WK IN CUR_MATERIAL_WK LOOP

        -- �Ǎ������J�E���g�A�b�v
        V_IN_COUNT := V_IN_COUNT + 1;
        -- �@ �G���[�t���O
        V_ERR_FLG := CONST_FLAG.C_FALSE;
        -- �A ���呶�݃`�F�b�N
        IF GET_V_DEPT_BASE_MAST(V_IN_COUNT, R_MATERIAL_WK.DEPT_NO, '����ԍ�') = 0 THEN
            V_ERR_FLG := CONST_FLAG.C_TRUE;
        END IF;
        -- �B ����ԍ��`�F�b�N
        IF SUBSTR(P_TOP_DEPT_NO, 0, 3) <> SUBSTR(R_MATERIAL_WK.DEPT_NO, 0, 3) THEN
            V_ERR_FLG := CONST_FLAG.C_TRUE;
            V_MSG := '����ԍ��i�擪�R�P�^�j�A���}�b�`�G���[�B' ||
            ' ���R�[�h�ԍ���['|| V_IN_COUNT || ']' ||
            ' �ŏ�ʕ���ԍ���['|| P_TOP_DEPT_NO || ']' ||
            ' ����ԍ���[' || R_MATERIAL_WK.DEPT_NO || ']';
            CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
        END IF;
        -- �C ���ޗ����o�敪�`�F�b�N
        R_EDI_CODE_TYPE_CONV := NULL;
        BEGIN
            R_EDI_CODE_TYPE_CONV := GET_EDI_CODE_TYPE_CONV(
                                    V_IN_COUNT, P_TOP_DEPT_NO,
                                    CONST_TR_PGM_SALES.C_EDI_DISTINCTION_TYPE_MC,
                                    CONST_CMNNO.C_MATERIAL_TAKE_OUT_TYPE, -- Z0373
                                    R_MATERIAL_WK.MC_ACXFR_RSN_CD,
                                    R_MATERIAL_WK.SLIP_DATE,
                                    '�l�b������U�֗��R�b�c');
        EXCEPTION
            WHEN OTHERS THEN
               -- �G���[�t���O
                V_ERR_FLG := CONST_FLAG.C_TRUE;
        END;
        --�敪�}�X�^������������B
        IF R_EDI_CODE_TYPE_CONV.TR_EDI_CODE_TYPE_CONV_ID IS NOT NULL THEN
            BEGIN
                R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(
                            P_TOP_DEPT_NO,
                            CONST_CMNNO.C_MATERIAL_TAKE_OUT_TYPE,
                            R_EDI_CODE_TYPE_CONV.CHAR_HEAD1);
            EXCEPTION
                WHEN OTHERS THEN
                    -- �G���[�t���O
                    V_ERR_FLG := CONST_FLAG.C_TRUE;

                    V_MSG := '�敪�}�X�^�����G���[�i���ޗ����o�敪�j�B'                     ||
                    ' ���R�[�h�ԍ���['              || V_IN_COUNT                           || ']' ||
                    ' �l�b������U�֗��R�b�c��['    || R_MATERIAL_WK.MC_ACXFR_RSN_CD        || ']' ||
                    ' �ŏ�ʕ���ԍ���['            || P_TOP_DEPT_NO                        || ']' ||
                    ' ���ʔԍ���['                  || CONST_CMNNO.C_MATERIAL_TAKE_OUT_TYPE || ']' ||
                    ' �敪�ԍ���['                  || R_EDI_CODE_TYPE_CONV.CHAR_HEAD1      || ']';
                    CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
            END;
        END IF;
        -- �D �݌Ɏ�ދ敪�`�F�b�N
        CHECK_INVENT_KIND_TYPE(V_IN_COUNT, R_MATERIAL_WK.INVENT_KIND_TYPE, V_ERR_FLG);

        -- �E ��v�N���`�F�b�N
        CHECK_FINAN_YM(V_IN_COUNT, V_FINAN_YM, R_MATERIAL_WK.FINAN_YM, '�l�b��v�N��', V_ERR_FLG);

        -- �F �ԍ��敪�`�F�b�N
        BEGIN
            R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(
                        CONST_CMNNO.C_RED_BLACK_TYPE, -- Z0088
                        R_MATERIAL_WK.RED_BLACK_TYPE);
            EXCEPTION
                WHEN OTHERS THEN
                    -- �G���[�t���O
                    V_ERR_FLG := CONST_FLAG.C_TRUE;
                    V_MSG := '�敪�}�X�^�����G���[�B'                   ||
                    ' ���R�[�h�ԍ���['  || V_IN_COUNT                   || ']' ||
                    ' �ԍ��敪��['      || R_MATERIAL_WK.RED_BLACK_TYPE || ']';
                    CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
        END;

        --�i�S�j�`�F�b�N������s���B
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

	-- �������O�\��
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '���ޗ��o��o���[�N�@�@�@�@�@�@�Ǎ�����: ' ||
        TO_CHAR(V_IN_COUNT,  '999,999')     || ' ��');
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '���ޗ��o��o���[�N�@�@�@�@�@�G���[����: ' ||
        TO_CHAR(V_ERR_COUNT,  '999,999')    || ' ��');

	-- ����I���������O�ɏo��
	IF V_ERR_COUNT = 0 THEN
    	-- �R�~�b�g����
    	COMMIT;
		CMN.INFO(V_JOB_ID
				,C_PACKAGE_NAME
				,C_INFOLOG_NAME || '������I�����܂����B');
	ELSE
        ROLLBACK;
		-- �v���O�����ُ�I���������O�ɏo��
		V_ERR_MSG := '���ޗ��o��o�f�[�^�G���[�`�F�b�N�ɂăG���[���������Ă��܂��B';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						NULL, NULL, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
	END IF;

	-- �㏈��
	CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);

    RETURN V_END_CODE;

EXCEPTION
	WHEN OTHERS THEN
		-- ���[���o�b�N
		ROLLBACK;
		-- �ُ�I���R�[�h���Z�b�g
		V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		-- �v���O�����ُ�I���������O�ɏo��
		V_ERR_MSG := '�\�����ʃG���[���������܂����B';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						SQLCODE, SQLERRM, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
END CHECK_MATERIAL_TAKE_OUT;
-- *****************************************************************************
--�@�v���O������ : 190_20_13_02 �݌Ɏc���f�[�^�G���[�`�F�b�N
--  @PARAM		I_JOB_ID			�W���uID
--  @PARAM		I_EXEC_JOB_ID		���s���[�UID
--  @PARAM		I_TOP_DEPT_NO		�ŏ�ʕ���ԍ�
--  @RETURN		�I���R�[�h
-- *****************************************************************************
FUNCTION CHECK_INVENT_BALANCE_AMO(
    I_JOB_ID                    IN NUMBER      --�W���u�h�c
    ,I_EXEC_JOB_ID              IN VARCHAR2    --���s���[�U�[�h�c
    ,I_TOP_DEPT_NO              IN VARCHAR2    --�ŏ�ʕ���ԍ�
)RETURN NUMBER
IS
    C_PROC_NAME		CONSTANT	VARCHAR2(30)
								:= 'CHECK_INVENT_BALANCE_AMO';
	-- ���O�o�͗p����
	C_INFOLOG_NAME	CONSTANT	VARCHAR2(30)
								:= '�݌Ɏc���f�[�^�G���[�`�F�b�N';

	V_MSG						VARCHAR2(4000); -- ���b�Z�[�W
	V_ERR_MSG					VARCHAR2(4000); -- �G���[���b�Z�[�W

    -- �����J�E���g
    V_IN_COUNT                  NUMBER;         --�Ǎ�����
    V_ERR_COUNT                 NUMBER;       	--�G���[����
    V_ERR_FLG                   VARCHAR2(1);    --�G���[�t���O

    V_FINAN_YM                  VARCHAR(6);     --��v�N��
    R_TYPE_MAST                 TYPE_MAST%ROWTYPE; --�敪�}�X�^���

	-- ���o�ΏۂƂȂ錴�ޗ��݌Ɏc�����[�N���擾����
	CURSOR CUR_MATERIAL_INVENT_BAL_WK IS
        SELECT      A.*
        FROM        TR_MATERIAL_INVENT_BAL_WK A
        WHERE       A.TOP_DEPT_NO = P_TOP_DEPT_NO
        ORDER BY    A.ID;
        --FOR UPDATE;

BEGIN

	-- ������
	V_END_CODE := CONST_BATCH_EXIT_CODE.C_NORMAL_EXIT;
	V_WARN_CNT := 0;			-- �x����������

	--����
	P_TOP_DEPT_NO := I_TOP_DEPT_NO;

	-- (1) �W���uID���擾
	V_JOB_ID := CMN.PRE_PROCESS(I_JOB_ID, I_EXEC_JOB_ID, C_PACKAGE_NAME);

	-- (2) �v���O�����J�n�������O�ɏo��
	CMN.INFO(V_JOB_ID
			,C_PACKAGE_NAME
			,C_INFOLOG_NAME || '���J�n���܂����B');

    --�i�R�j��v�N�����擾����B
    V_FINAN_YM := CMN_OPER_ADMIN.GET_TOP_DEPT_FINAN_YM(P_TOP_DEPT_NO);

    -- �V�X�e�����t���擾
	V_SYSDATE := SYSDATE;

    -- �J�E���g�[���N���A
    V_IN_COUNT := 0;
    V_ERR_COUNT := 0;

	-- �{����

	FOR R_MATERIAL_INVENT_BAL_WK IN CUR_MATERIAL_INVENT_BAL_WK LOOP

        -- �Ǎ������J�E���g�A�b�v
        V_IN_COUNT := V_IN_COUNT + 1;
        -- �@ �G���[�t���O
        V_ERR_FLG := CONST_FLAG.C_FALSE;
        -- �A �݌Ɏd���ʃ`�F�b�N
        CHECK_INVENT_JNL_KIND_TYPE(V_IN_COUNT,
                                   R_MATERIAL_INVENT_BAL_WK.INVENT_JNL_KIND_TYPE,
                                   V_ERR_FLG);
        -- �B ��v�N���`�F�b�N
        CHECK_FINAN_YM(V_IN_COUNT, V_FINAN_YM, R_MATERIAL_INVENT_BAL_WK.FINAN_YM, '��v�N��', V_ERR_FLG);
        -- �C �ԍ��敪�`�F�b�N
        BEGIN
            R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(
                        CONST_CMNNO.C_RED_BLACK_TYPE,
                        R_MATERIAL_INVENT_BAL_WK.RED_BLACK_TYPE);
            EXCEPTION
                WHEN OTHERS THEN
                    -- �G���[�t���O
                    V_ERR_FLG := CONST_FLAG.C_TRUE;
                    V_MSG := '�敪�}�X�^�����G���[�B'                               ||
                    ' ���R�[�h�ԍ���['  || V_IN_COUNT                               || ']' ||
                    ' �ԍ��敪��['      || R_MATERIAL_INVENT_BAL_WK.RED_BLACK_TYPE  || ']';
                    CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
        END;

        --�i�S�j�`�F�b�N������s���B
        IF V_ERR_FLG = CONST_FLAG.C_TRUE THEN
            V_ERR_COUNT := V_ERR_COUNT + 1;
        END IF;
    END LOOP;

	-- �������O�\��
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '���ޗ��݌Ɏc�����[�N�@�@�@�@�@�@�Ǎ�����: ' ||
        TO_CHAR(V_IN_COUNT,  '999,999')     || ' ��');
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '���ޗ��݌Ɏc�����[�N�@�@�@�@�@�G���[����: ' ||
        TO_CHAR(V_ERR_COUNT,  '999,999')    || ' ��');

	-- ����I���������O�ɏo��
	IF V_ERR_COUNT <> 0 THEN
		-- �v���O�����ُ�I���������O�ɏo��
		V_ERR_MSG := '�݌Ɏc���f�[�^�G���[�`�F�b�N�ɂăG���[���������Ă��܂��B';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						NULL, NULL, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
        -- ��L���b�Z�[�W�o�͌�A�I����������B
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
	END IF;
    -- �I�����O���o�͂���B
    CMN.INFO(V_JOB_ID
        ,C_PACKAGE_NAME
        ,C_INFOLOG_NAME || '������I�����܂����B');
	-- �㏈��
	CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);

    RETURN V_END_CODE;

EXCEPTION
	WHEN OTHERS THEN
		-- �ُ�I���R�[�h���Z�b�g
		V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		-- �v���O�����ُ�I���������O�ɏo��
		V_ERR_MSG := '�\�����ʃG���[���������܂����B';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						SQLCODE, SQLERRM, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
END CHECK_INVENT_BALANCE_AMO;

-- *****************************************************************************
--�@�v���O������ : 190_20_14_02 ���i�o�׃f�[�^�G���[�`�F�b�N
--  @PARAM		I_JOB_ID			�W���uID
--  @PARAM		I_EXEC_JOB_ID		���s���[�UID
--  @PARAM		I_TOP_DEPT_NO		�ŏ�ʕ���ԍ�
--  @RETURN		�I���R�[�h
-- *****************************************************************************
FUNCTION CHECK_GOODS_OUT_GO(
    I_JOB_ID                    IN NUMBER      --�W���u�h�c
    ,I_EXEC_JOB_ID              IN VARCHAR2    --���s���[�U�[�h�c
    ,I_TOP_DEPT_NO              IN VARCHAR2    --�ŏ�ʕ���ԍ�
)RETURN NUMBER
IS
    C_PROC_NAME		CONSTANT	VARCHAR2(30)
								:= 'CHECK_GOODS_OUT_GO';
	-- ���O�o�͗p����
	C_INFOLOG_NAME	CONSTANT	VARCHAR2(30)
								:= '���i�o�׃f�[�^�G���[�`�F�b�N';

	V_MSG						VARCHAR2(4000); -- ���b�Z�[�W
	V_ERR_MSG					VARCHAR2(4000); -- �G���[���b�Z�[�W

    -- �����J�E���g
    V_IN_COUNT                  NUMBER;         --�Ǎ�����
    V_ERR_COUNT                 NUMBER;       	--�G���[����
    V_ERR_FLG                   VARCHAR2(1);    --�G���[�t���O
    V_PARAM_ERR_FLG             VARCHAR2(1);    -- ���Z�p�G���[�t���O

    V_FINAN_YM                              VARCHAR(6);     --��v�N��
    R_TYPE_MAST                             TYPE_MAST%ROWTYPE; --�敪�}�X�^���
    R_EDI_CODE_TYPE_CONV_PLACE              TR_EDI_CODE_TYPE_CONV%ROWTYPE; --�d�c�h�R�[�h�敪�ϊ�(����) PLACE
    R_EDI_CODE_TYPE_CONV_UNIT               TR_EDI_CODE_TYPE_CONV%ROWTYPE; --�d�c�h�R�[�h�敪�ϊ�(����) UNIT
    V_QTY                                   NUMBER; --���Z�㐔��

	-- ���o�ΏۂƂȂ鐻�i�o�׃��[�N���擾����i�������ׁj�B
	CURSOR CUR_PRODUCT_SHIP_WK IS
        SELECT      A.*
        FROM        TR_PRODUCT_SHIP_WK A
        WHERE       A.TOP_DEPT_NO = P_TOP_DEPT_NO
        ORDER BY    A.ID
        FOR UPDATE;

BEGIN

	-- ������
	V_END_CODE := CONST_BATCH_EXIT_CODE.C_NORMAL_EXIT;
	V_WARN_CNT := 0;			-- �x����������

	--����
	P_TOP_DEPT_NO := I_TOP_DEPT_NO;

	-- (1) �W���uID���擾
	V_JOB_ID := CMN.PRE_PROCESS(I_JOB_ID, I_EXEC_JOB_ID, C_PACKAGE_NAME);

	-- (2) �v���O�����J�n�������O�ɏo��
	CMN.INFO(V_JOB_ID
			,C_PACKAGE_NAME
			,C_INFOLOG_NAME || '���J�n���܂����B');

    --�i�R�j��v�N�����擾����B
    V_FINAN_YM := CMN_OPER_ADMIN.GET_TOP_DEPT_FINAN_YM(P_TOP_DEPT_NO);

    -- �V�X�e�����t���擾
	V_SYSDATE := SYSDATE;

    -- �J�E���g�[���N���A
    V_IN_COUNT := 0;
    V_ERR_COUNT := 0;

	-- �{����

	FOR R_PRODUCT_SHIP_WK IN CUR_PRODUCT_SHIP_WK LOOP

        -- �Ǎ������J�E���g�A�b�v
        V_IN_COUNT := V_IN_COUNT + 1;
        -- �@ �G���[�t���O
        V_ERR_FLG := CONST_FLAG.C_FALSE;
        V_PARAM_ERR_FLG := CONST_FLAG.C_FALSE;
        -- �A ���i�R�[�h�`�F�b�N
        IF GET_GOODS_MAST(V_IN_COUNT, R_PRODUCT_SHIP_WK.GOODS_CODE) = 0 THEN
            -- �G���[�t���O
            V_ERR_FLG := CONST_FLAG.C_TRUE;
            V_PARAM_ERR_FLG := CONST_FLAG.C_TRUE;
        END IF;
        -- �A �ԍ��敪�`�F�b�N
        BEGIN
            R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(CONST_CMNNO.C_RED_BLACK_TYPE, R_PRODUCT_SHIP_WK.RED_BLACK_TYPE);
        EXCEPTION
            WHEN OTHERS THEN
                -- �G���[�t���O
                V_ERR_FLG := CONST_FLAG.C_TRUE;
                V_MSG := '�敪�}�X�^�����G���[�B'                          ||
                ' ���R�[�h�ԍ���[' || V_IN_COUNT                           || ']' ||
                ' �ԍ��敪��['     || R_PRODUCT_SHIP_WK.RED_BLACK_TYPE     || ']';
                CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
        END;
        -- �B �ꏊ�R�[�h�`�F�b�N
        -- a)	�d�c�h�R�[�h�敪�ϊ�(����)����������i�P���ڂ̃��R�[�h�̍��ڂ��擾��A�N���[�Y���邱�Ɓj�B
        R_EDI_CODE_TYPE_CONV_PLACE := NULL;
        BEGIN
              R_EDI_CODE_TYPE_CONV_PLACE := GET_EDI_CODE_TYPE_CONV(
                                            V_IN_COUNT,
                                            P_TOP_DEPT_NO,
                                            CONST_TR_PGM_SALES.C_EDI_DISTINCTION_TYPE_MC,
                                            '100',
                                            R_PRODUCT_SHIP_WK.MC_PLACE_CODE,
                                            R_PRODUCT_SHIP_WK.SHIP_DATE,
                                            '�l�b�ꏊ�R�[�h');
        -- b)	���R�[�h���擾�ł��Ȃ��ꍇ�A�G���[�t���O�i�ϐ��j��TRUE�ɂ��A�G���[���b�Z�[�W���o�͂���B
        EXCEPTION
            WHEN OTHERS THEN
                -- �G���[�t���O
                V_ERR_FLG := CONST_FLAG.C_TRUE;

        END;
        -- c)	���R�[�h���擾�ł����ꍇ�A�d�c�h�R�[�h�敪�ϊ�(����)�̍��ڂ��`�F�b�N����B
        IF R_EDI_CODE_TYPE_CONV_PLACE.TR_EDI_CODE_TYPE_CONV_ID IS NOT NULL THEN
            -- �)	�q�Ƀ}�X�^����������B�y�q�ɑ��݃`�F�b�N�z
            IF GET_WAREHOUSE(V_IN_COUNT, P_TOP_DEPT_NO,
                             R_EDI_CODE_TYPE_CONV_PLACE.CHAR_HEAD1,
                             R_PRODUCT_SHIP_WK.MC_PLACE_CODE,
                             '�l�b�ꏊ�R�[�h') = 0 THEN
                -- �G���[�t���O
                V_ERR_FLG := CONST_FLAG.C_TRUE;
            END IF;
            -- �)	�d�c�h�R�[�h�敪�ϊ��i���Ёj�D�����f�[�^�Q��NULL�̏ꍇ�A�݌ɒu��}�X�^����������B
            IF R_EDI_CODE_TYPE_CONV_PLACE.CHAR_HEAD2 IS NOT NULL THEN
                IF GET_INVENT_PLACE(V_IN_COUNT, P_TOP_DEPT_NO,
                                    R_EDI_CODE_TYPE_CONV_PLACE.CHAR_HEAD1,
                                    R_EDI_CODE_TYPE_CONV_PLACE.CHAR_HEAD2,
                                    R_PRODUCT_SHIP_WK.MC_PLACE_CODE,
                                    '�l�b�ꏊ�R�[�h') = 0 THEN
                    -- �G���[�t���O
                    V_ERR_FLG := CONST_FLAG.C_TRUE;
                END IF;
            END IF;
            -- �) �敪�}�X�^�����擾
            BEGIN
                R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(
                    P_TOP_DEPT_NO, CONST_CMNNO.C_STRONG_POINT_TYPE,
                    R_EDI_CODE_TYPE_CONV_PLACE.CHAR_HEAD3);
                EXCEPTION
                    WHEN OTHERS THEN
                        -- �G���[�t���O
                        V_ERR_FLG := CONST_FLAG.C_TRUE;
                        V_MSG := '�敪�}�X�^�����G���[�i���_�j�B' ||
                                ' ���R�[�h�ԍ���['   || V_IN_COUNT                               || ']' ||
                                ' �l�b�ꏊ�R�[�h��[' || R_PRODUCT_SHIP_WK.MC_PLACE_CODE          || ']' ||
                                ' �q�ɔԍ���['       || R_EDI_CODE_TYPE_CONV_PLACE.CHAR_HEAD1    || ']' ||
                                ' �u��ԍ���['       || R_EDI_CODE_TYPE_CONV_PLACE.CHAR_HEAD2    || ']' ||
                                ' ���_�敪��['       || R_EDI_CODE_TYPE_CONV_PLACE.CHAR_HEAD3    || ']';
                        CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
            END;
        END IF;
        -- �C �l�b��P�ʂb�c�`�F�b�N
        R_EDI_CODE_TYPE_CONV_UNIT := NULL;
        BEGIN
            R_EDI_CODE_TYPE_CONV_UNIT := GET_EDI_CODE_TYPE_CONV(
                                        V_IN_COUNT, P_TOP_DEPT_NO,
                                        CONST_TR_PGM_SALES.C_EDI_DISTINCTION_TYPE_MC,
                                        CONST_CMNNO.C_UNIT_TYPE,
                                        R_PRODUCT_SHIP_WK.MC_UNIT_CD,
                                        R_PRODUCT_SHIP_WK.SHIP_DATE,
                                        '�l�b��P�ʂb�c');
            EXCEPTION
                WHEN OTHERS THEN
                    -- �G���[�t���O
                    V_ERR_FLG := CONST_FLAG.C_TRUE;
                    V_PARAM_ERR_FLG := CONST_FLAG.C_TRUE;
            END;

        -- �D ���Z�p�G���[�t���O�i�ϐ��j��FALSE�̏ꍇ�A��P�ʊ��Z�`�F�b�N
        IF V_PARAM_ERR_FLG = CONST_FLAG.C_FALSE THEN
            BEGIN
                V_QTY := CMN_GOODS_PARTS.CONVERT_GOODS_BASE_UNIT(
                        R_PRODUCT_SHIP_WK.GOODS_CODE,
                        1, R_EDI_CODE_TYPE_CONV_UNIT.CHAR_HEAD1,
                        NULL, NULL, P_TOP_DEPT_NO);
            EXCEPTION
                WHEN OTHERS THEN
                    -- �G���[�t���O
                    V_ERR_FLG := CONST_FLAG.C_TRUE;
                    V_MSG := '��{�P�ʊ��Z�G���[�B'                                     ||
                    ' ���R�[�h�ԍ���['        || V_IN_COUNT                             || ']' ||
                    ' �l�b��P�ʂb�c��['    || R_PRODUCT_SHIP_WK.MC_UNIT_CD           || ']' ||
                    ' �P�ʋ敪��['            || R_EDI_CODE_TYPE_CONV_UNIT.CHAR_HEAD1   || ']' ||
                    ' ���i�R�[�h��['          || R_PRODUCT_SHIP_WK.GOODS_CODE           || ']';
                    CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
            END;
        END IF;

        -- �E ��v�N���`�F�b�N
        CHECK_FINAN_YM(V_IN_COUNT, V_FINAN_YM, R_PRODUCT_SHIP_WK.FINAN_YM, '��v�N��', V_ERR_FLG);

        IF V_ERR_FLG = CONST_FLAG.C_TRUE THEN
            V_ERR_COUNT := V_ERR_COUNT + 1;
        END IF;

        IF V_ERR_COUNT = 0 THEN
            UPDATE TR_PRODUCT_SHIP_WK
               SET WAREHOUSE_NO       = R_EDI_CODE_TYPE_CONV_PLACE.CHAR_HEAD1,  --�q�ɔԍ�
                   INVENT_PLACE_NO    = R_EDI_CODE_TYPE_CONV_PLACE.CHAR_HEAD2,  --�݌ɒu��ԍ�
                   STRONG_POINT_TYPE  = R_EDI_CODE_TYPE_CONV_PLACE.CHAR_HEAD3,  --���_�敪
                   SHIP_QTY_UNIT_TYPE = R_EDI_CODE_TYPE_CONV_UNIT.CHAR_HEAD1,   --�o�א��ʒP�ʋ敪
                   REG_DATE_TIME      = V_SYSDATE                               --�o�^����
             WHERE CURRENT OF CUR_PRODUCT_SHIP_WK;
        END IF;

    END LOOP;

	-- �������O�\��
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '���i�o�׃��[�N�@�@�@�@�@�@�Ǎ�����: ' ||
        TO_CHAR(V_IN_COUNT,  '999,999')     || ' ��');
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '���i�o�׃��[�N�@�@�@�@�@�G���[����: ' ||
        TO_CHAR(V_ERR_COUNT,  '999,999')    || ' ��');

	-- ����I���������O�ɏo��
	IF V_ERR_COUNT <> 0 THEN
        ROLLBACK;
		-- �v���O�����ُ�I���������O�ɏo��
		V_ERR_MSG := '���i�o�׃f�[�^�G���[�`�F�b�N�ɂăG���[���������Ă��܂��B';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						NULL, NULL, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
        -- ��L���b�Z�[�W�o�͌�A�I����������B
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
    ELSE
        COMMIT;
        CMN.INFO(V_JOB_ID
				,C_PACKAGE_NAME
				,C_INFOLOG_NAME || '������I�����܂����B');
	END IF;

	-- �㏈��
	CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);

    RETURN V_END_CODE;

EXCEPTION
	WHEN OTHERS THEN
        ROLLBACK;
		-- �ُ�I���R�[�h���Z�b�g
		V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		-- �v���O�����ُ�I���������O�ɏo��
		V_ERR_MSG := '�\�����ʃG���[���������܂����B';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						SQLCODE, SQLERRM, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
END CHECK_GOODS_OUT_GO;

-- *****************************************************************************
--�@�v���O������ : 190_20_16_02 ���������f�[�^�G���[�`�F�b�N
--  @PARAM		I_JOB_ID			�W���uID
--  @PARAM		I_EXEC_JOB_ID		���s���[�UID
--  @PARAM		I_TOP_DEPT_NO		�ŏ�ʕ���ԍ�
--  @RETURN		�I���R�[�h
-- *****************************************************************************
FUNCTION CHECK_PROD_COST(
        I_JOB_ID                    IN NUMBER      --�W���u�h�c
        ,I_EXEC_JOB_ID              IN VARCHAR2    --���s���[�U�[�h�c
        ,I_TOP_DEPT_NO              IN VARCHAR2    --�ŏ�ʕ���ԍ�
    )RETURN NUMBER
IS
    C_PROC_NAME		CONSTANT	VARCHAR2(30)
								:= 'CHECK_PROD_COST';
	-- ���O�o�͗p����
	C_INFOLOG_NAME	CONSTANT	VARCHAR2(30)
								:= '���������f�[�^�G���[�`�F�b�N';

	V_ERR_MSG					VARCHAR2(4000); -- �G���[���b�Z�[�W

    -- �����J�E���g
    V_IN_COUNT                  NUMBER;         --�Ǎ�����
    V_ERR_COUNT                 NUMBER;       	--�G���[����
    V_ERR_FLG                   VARCHAR2(1);    --�G���[�t���O

    V_FINAN_YM                              VARCHAR(6);     --��v�N��
    V_FINAN_YEAR                            VARCHAR2(4);    --��v�N�x
    V_PROD_COST_FINAN_YEAR                  VARCHAR2(4);    --��v�N�x�i�����������[�N���j
    V_CONTINUE_FLG                          VARCHAR2(1);
    R_EDI_CODE_TYPE_CONV                    TR_EDI_CODE_TYPE_CONV%ROWTYPE; --�d�c�h�R�[�h�敪�ϊ�
    V_FINAN_DATE                            DATE; --��v�N���̂P��
    R_TYPE_MAST                             TYPE_MAST%ROWTYPE; --�敪�}�X�^���
    --���o�ΏۂƂȂ鐻���������[�N���擾����i�������ׁj�B
	CURSOR CUR_PROD_COST_WK IS
        SELECT      A.*
        FROM        TR_PROD_COST_WK A
        WHERE       A.TOP_DEPT_NO = P_TOP_DEPT_NO
        ORDER BY    A.ID
        FOR         UPDATE;
BEGIN

	-- ������
	V_END_CODE := CONST_BATCH_EXIT_CODE.C_NORMAL_EXIT;
	V_WARN_CNT := 0;			-- �x����������

	--����
	P_TOP_DEPT_NO := I_TOP_DEPT_NO;

	-- (1) �W���uID���擾
	V_JOB_ID := CMN.PRE_PROCESS(I_JOB_ID, I_EXEC_JOB_ID, C_PACKAGE_NAME);

	-- (2) �v���O�����J�n�������O�ɏo��
	CMN.INFO(V_JOB_ID
			,C_PACKAGE_NAME
			,C_INFOLOG_NAME || '���J�n���܂����B');

    --�i�R�j��v�N�����擾����B
    V_FINAN_YM := CMN_OPER_ADMIN.GET_TOP_DEPT_FINAN_YM(P_TOP_DEPT_NO);

    --�i�S�j���Z�N�x���擾����B
    V_FINAN_YEAR := CMN_UTL_CLNDR.GET_FINAN_YEAR(V_FINAN_YM);

    -- �V�X�e�����t���擾
	V_SYSDATE := SYSDATE;

    -- �J�E���g�[���N���A
    V_IN_COUNT := 0;
    V_ERR_COUNT := 0;

	-- �{����

	FOR R_PROD_COST_WK IN CUR_PROD_COST_WK LOOP
        -- �Ǎ������J�E���g�A�b�v
        V_IN_COUNT := V_IN_COUNT + 1;
        -- �@ �G���[�t���O
        V_ERR_FLG := CONST_FLAG.C_FALSE;
        V_CONTINUE_FLG := CONST_FLAG.C_TRUE;
        -- �A ���i�R�[�h�`�F�b�N
        IF GET_GOODS_MAST(V_IN_COUNT, R_PROD_COST_WK.GOODS_CODE) = 0 THEN
            -- �G���[�t���O
            V_ERR_FLG := CONST_FLAG.C_TRUE;
        END IF;
		IF SUBSTR(R_PROD_COST_WK.GOODS_CODE, 0, 3) <> SUBSTR(P_TOP_DEPT_NO, 0, 3) THEN
			-- �G���[�t���O
            V_ERR_FLG := CONST_FLAG.C_TRUE;
			V_ERR_MSG := '���i�R�[�h�i�擪�R�P�^�j�A���}�b�`�G���[�B' ||
						'���R�[�h�ԍ���['		||	V_IN_COUNT					|| ']' ||
						'���i�R�[�h��['		 ||	R_PROD_COST_WK.GOODS_CODE	 || ']' ||
						'�ŏ�ʕ���ԍ���['	   || P_TOP_DEPT_NO				   || ']';
			CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_ERR_MSG);
		END IF;
        -- �C �N�x�`�F�b�N
        V_PROD_COST_FINAN_YEAR := CMN_UTL_CLNDR.GET_FINAN_YEAR(R_PROD_COST_WK.FINAN_YM);
        CHECK_FINAN_YEAR(V_IN_COUNT, V_FINAN_YEAR, V_PROD_COST_FINAN_YEAR, V_ERR_FLG);
        -- �D ��v�N���`�F�b�N
        CHECK_FINAN_YM(V_IN_COUNT, V_FINAN_YM, R_PROD_COST_WK.FINAN_YM, '�l�b��v�N��', V_ERR_FLG);
        -- �E �݌Ɍv�Z���@�敪�`�F�b�N
        CHECK_INVENT_CALC_TYPE(V_IN_COUNT, R_PROD_COST_WK.INVENT_CALC_TYPE, V_ERR_FLG);
        -- �F �l�b�v�Z�O���[�v�b�c�`�F�b�N
        -- a) �d�c�h�R�[�h�敪�ϊ�(����)����������i�P���ڂ̃��R�[�h�̍��ڂ��擾��A�N���[�Y���邱�Ɓj�B
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
                                '�l�b�v�Z�O���[�v�b�c'
                            );
        EXCEPTION
            WHEN OTHERS THEN
                V_ERR_FLG := CONST_FLAG.C_TRUE;
        END;
        IF R_EDI_CODE_TYPE_CONV.TR_EDI_CODE_TYPE_CONV_ID IS NOT NULL THEN
            -- c)	���R�[�h���擾�ł����ꍇ�A�d�c�h�R�[�h�敪�ϊ�(����)�̍��ڂ��`�F�b�N����B
            -- �)	�q�Ƀ}�X�^����������B�y�q�ɑ��݃`�F�b�N�z
            IF GET_WAREHOUSE(V_IN_COUNT, P_TOP_DEPT_NO,
                R_EDI_CODE_TYPE_CONV.CHAR_HEAD1,
                R_PROD_COST_WK.MC_CALC_GRP_CD,
                '�l�b�v�Z�O���[�v�b�c') = 0 THEN
                V_ERR_FLG := CONST_FLAG.C_TRUE;
                V_CONTINUE_FLG := CONST_FLAG.C_FALSE;
            END IF;
            -- �)	�d�c�h�R�[�h�敪�ϊ��i���Ёj�D�����f�[�^�Q��NULL�̏ꍇ�A�݌ɒu��}�X�^����������
            IF V_CONTINUE_FLG = CONST_FLAG.C_TRUE THEN
                IF R_EDI_CODE_TYPE_CONV.CHAR_HEAD2 IS NOT NULL THEN
                    IF GET_INVENT_PLACE(V_IN_COUNT, P_TOP_DEPT_NO,
                        R_EDI_CODE_TYPE_CONV.CHAR_HEAD1,
                        R_EDI_CODE_TYPE_CONV.CHAR_HEAD2,
                        R_PROD_COST_WK.MC_CALC_GRP_CD,
                        '�l�b�v�Z�O���[�v�b�c') = 0 THEN
                        V_ERR_FLG := CONST_FLAG.C_TRUE;
                        V_CONTINUE_FLG := CONST_FLAG.C_FALSE;
                    END IF;
                END IF;
                -- �敪�}�X�^�����擾
                IF V_CONTINUE_FLG = CONST_FLAG.C_TRUE THEN
                    BEGIN
                    R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(P_TOP_DEPT_NO,
                                    CONST_CMNNO.C_STRONG_POINT_TYPE, R_EDI_CODE_TYPE_CONV.CHAR_HEAD3);
                    EXCEPTION
                        WHEN OTHERS THEN
                            V_ERR_FLG := CONST_FLAG.C_TRUE;
                            V_ERR_MSG := '�敪�}�X�^�����G���[�i���_�j�B' ||
                                     ' ���R�[�h�ԍ���['          || V_IN_COUNT || ']' ||
                                     ' �l�b�v�Z�O���[�v�b�c��['  || R_PROD_COST_WK.MC_CALC_GRP_CD    || ']' ||
                                     ' �q�ɔԍ���['              || R_EDI_CODE_TYPE_CONV.CHAR_HEAD1  || ']' ||
                                     ' �u��ԍ���['              || R_EDI_CODE_TYPE_CONV.CHAR_HEAD2  || ']' ||
                                     ' ���_�敪��['              || R_EDI_CODE_TYPE_CONV.CHAR_HEAD3  || ']';
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

	-- �������O�\��
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '�����������[�N�@�@�@�@�@�@�Ǎ�����: ' ||
        TO_CHAR(V_IN_COUNT,  '999,999')     || ' ��');
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '�����������[�N�@�@�@�@�@�G���[����: ' ||
        TO_CHAR(V_ERR_COUNT,  '999,999')    || ' ��');

	-- ����I���������O�ɏo��
	IF V_ERR_COUNT <> 0 THEN
        ROLLBACK;
		-- �v���O�����ُ�I���������O�ɏo��
		V_ERR_MSG := '���������f�[�^�G���[�`�F�b�N�ɂăG���[���������Ă��܂��B';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						NULL, NULL, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
        -- ��L���b�Z�[�W�o�͌�A�I����������B
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
    ELSE
        COMMIT;
        CMN.INFO(V_JOB_ID
				,C_PACKAGE_NAME
				,C_INFOLOG_NAME || '������I�����܂����B');
	END IF;

	-- �㏈��
	CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);

    RETURN V_END_CODE;

EXCEPTION
	WHEN OTHERS THEN
        ROLLBACK;
		-- �ُ�I���R�[�h���Z�b�g
		V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		-- �v���O�����ُ�I���������O�ɏo��
		V_ERR_MSG := '�\�����ʃG���[���������܂����B';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						SQLCODE, SQLERRM, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;

END CHECK_PROD_COST;

-- *****************************************************************************
--�@�v���O������ : 190_20_17_02 ���i�}�X�^�f�[�^�G���[�`�F�b�N
--  @PARAM		I_JOB_ID			�W���uID
--  @PARAM		I_EXEC_JOB_ID		���s���[�UID
--  @PARAM		I_TOP_DEPT_NO		�ŏ�ʕ���ԍ�
--  @RETURN		�I���R�[�h
-- *****************************************************************************
FUNCTION CHECK_GOODS_MAST(
    I_JOB_ID                    IN NUMBER      --�W���u�h�c
    ,I_EXEC_JOB_ID              IN VARCHAR2    --���s���[�U�[�h�c
    ,I_TOP_DEPT_NO              IN VARCHAR2    --�ŏ�ʕ���ԍ�
)RETURN NUMBER
IS
    C_PROC_NAME		CONSTANT	VARCHAR2(30)
								:= 'CHECK_GOODS_MAST';
	-- ���O�o�͗p����
	C_INFOLOG_NAME	CONSTANT	VARCHAR2(30)
								:= '���i�}�X�^�f�[�^�G���[�`�F�b�N';

	V_MSG						VARCHAR2(4000); -- ���b�Z�[�W
	V_ERR_MSG					VARCHAR2(4000); -- �G���[���b�Z�[�W

    -- �����J�E���g
    V_IN_COUNT                  NUMBER;         --�Ǎ�����
    V_ERR_COUNT                 NUMBER;       	--�G���[����
    V_ERR_FLG                   VARCHAR2(1);    --�G���[�t���O

    R_TYPE_MAST                             TYPE_MAST%ROWTYPE; --�敪�}�X�^���
    R_EDI_CODE_TYPE_CONV_UNIT               TR_EDI_CODE_TYPE_CONV%ROWTYPE; --�d�c�h�R�[�h�敪�ϊ�(����) UNIT
    V_OPER_LATE_DATE                        DATE; -- �^�p�������t

	-- ���o�ΏۂƂȂ鏤�i�}�X�^���[�N���擾����i�������ׁj�B
	CURSOR CUR_GOODS_MAST_WK IS
        SELECT      A.*
        FROM        TR_GOODS_MAST_WK A
        WHERE       A.TOP_DEPT_NO = P_TOP_DEPT_NO
        ORDER BY    A.ID
        FOR UPDATE;

BEGIN

	-- ������
	V_END_CODE := CONST_BATCH_EXIT_CODE.C_NORMAL_EXIT;
	V_WARN_CNT := 0;			-- �x����������

	--����
	P_TOP_DEPT_NO := I_TOP_DEPT_NO;

	-- (1) �W���uID���擾
	V_JOB_ID := CMN.PRE_PROCESS(I_JOB_ID, I_EXEC_JOB_ID, C_PACKAGE_NAME);

	-- (2) �v���O�����J�n�������O�ɏo��
	CMN.INFO(V_JOB_ID
			,C_PACKAGE_NAME
			,C_INFOLOG_NAME || '���J�n���܂����B');

    --�i�R�j�^�p�������t���擾����B
    V_OPER_LATE_DATE := CMN_OPER_ADMIN.GET_LATE_DATE;

    -- �V�X�e�����t���擾
	V_SYSDATE := SYSDATE;

    -- �J�E���g�[���N���A
    V_IN_COUNT := 0;
    V_ERR_COUNT := 0;

	-- �{����

	FOR R_GOODS_MAST_WK IN CUR_GOODS_MAST_WK LOOP

        -- �Ǎ������J�E���g�A�b�v
        V_IN_COUNT := V_IN_COUNT + 1;
        -- �@ �G���[�t���O
        V_ERR_FLG := CONST_FLAG.C_FALSE;
        --�@-1	���i�R�[�h�`�F�b�N
        IF SUBSTR(R_GOODS_MAST_WK.TOP_DEPT_NO, 0, 3) <> SUBSTR(R_GOODS_MAST_WK.GOODS_CODE, 0, 3) THEN
            --�G���[�t���O
            V_ERR_FLG := CONST_FLAG.C_TRUE;
            V_MSG := '���i�R�[�h�G���[�i���i�R�[�h��3��'
                    || SUBSTR(R_GOODS_MAST_WK.TOP_DEPT_NO, 0, 3)  || '�ȊO�͘A�g�s�j'
                    || ' ���R�[�h�ԍ���['                         || V_IN_COUNT                    || ']'
                    || ' ���i�R�[�h��['                           || R_GOODS_MAST_WK.GOODS_CODE    || ']';
            CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
        END IF;
        -- �A �l�b��P�ʂb�c�`�F�b�N
        R_EDI_CODE_TYPE_CONV_UNIT := NULL;
        BEGIN
            R_EDI_CODE_TYPE_CONV_UNIT := GET_EDI_CODE_TYPE_CONV(
                                        V_IN_COUNT,
                                        P_TOP_DEPT_NO,
                                        CONST_TR_PGM_SALES.C_EDI_DISTINCTION_TYPE_MC,
                                        CONST_CMNNO.C_UNIT_TYPE,
                                        R_GOODS_MAST_WK.MC_UNIT_CD,
                                        V_OPER_LATE_DATE,
                                        '�l�b��P�ʂb�c');
        EXCEPTION
            WHEN OTHERS THEN
                -- �G���[�t���O
                V_ERR_FLG := CONST_FLAG.C_TRUE;
        END;
        IF R_EDI_CODE_TYPE_CONV_UNIT.TR_EDI_CODE_TYPE_CONV_ID IS NOT NULL THEN
            BEGIN
                R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(
                            CONST_CMNNO.C_UNIT_TYPE,
                            R_EDI_CODE_TYPE_CONV_UNIT.CHAR_HEAD1);
            EXCEPTION
                WHEN OTHERS THEN
                    V_MSG := '�敪�}�X�^�����G���[�B' ||
                    ' ���R�[�h�ԍ���['          || V_IN_COUNT                           || ']' ||
                    ' �l�b��P�ʂb�c��['      || R_GOODS_MAST_WK.MC_UNIT_CD           || ']' ||
                    ' �P�ʋ敪��['              || R_EDI_CODE_TYPE_CONV_UNIT.CHAR_HEAD1 || ']';
                    CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
                    V_ERR_FLG := CONST_FLAG.C_TRUE;
            END;
        END IF;
        -- �B �݌Ɏ�ދ敪�`�F�b�N
        IF R_GOODS_MAST_WK.INVENT_KIND_TYPE <> CONST_TR_PGM_SALES.C_INVENT_SORT_TYPE_MATERIAL
            AND R_GOODS_MAST_WK.INVENT_KIND_TYPE <> CONST_TR_PGM_SALES.C_INVENT_SORT_TYPE_STORED
            AND R_GOODS_MAST_WK.INVENT_KIND_TYPE <> CONST_TR_PGM_SALES.C_INVENT_SORT_TYPE_PRODUCT
        THEN
            V_MSG := '�݌Ɏ�ޑΏۊO�G���[�B' ||
            ' ���R�[�h�ԍ���['   || V_IN_COUNT                          || ']' ||
            ' �݌Ɏ�ދ敪��['   || R_GOODS_MAST_WK.INVENT_KIND_TYPE    || ']';
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

	-- �������O�\��
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '���i�}�X�^���[�N�@�@�@�@�@�@�Ǎ�����: ' ||
        TO_CHAR(V_IN_COUNT,  '999,999')     || ' ��');
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '���i�}�X�^���[�N�@�@�@�@�@�G���[����: ' ||
        TO_CHAR(V_ERR_COUNT,  '999,999')    || ' ��');

	-- ����I���������O�ɏo��
	IF V_ERR_COUNT <> 0 THEN
        ROLLBACK;
		-- �v���O�����ُ�I���������O�ɏo��
		V_ERR_MSG := '���i�}�X�^�f�[�^�G���[�`�F�b�N�ɂăG���[���������Ă��܂��B';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						NULL, NULL, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
        -- ��L���b�Z�[�W�o�͌�A�I����������B
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
    ELSE
        COMMIT;
        CMN.INFO(V_JOB_ID
				,C_PACKAGE_NAME
				,C_INFOLOG_NAME || '������I�����܂����B');
	END IF;

	-- �㏈��
	CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);

    RETURN V_END_CODE;

EXCEPTION
	WHEN OTHERS THEN
        ROLLBACK;
		-- �ُ�I���R�[�h���Z�b�g
		V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		-- �v���O�����ُ�I���������O�ɏo��
		V_ERR_MSG := '�\�����ʃG���[���������܂����B';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						SQLCODE, SQLERRM, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
END CHECK_GOODS_MAST;

-- *****************************************************************************
--�@�v���O������ : 190_20_19_02   �d�|�����f�[�^�G���[�`�F�b�N
--  @PARAM		I_JOB_ID			�W���uID
--  @PARAM		I_EXEC_JOB_ID		���s���[�UID
--  @PARAM		I_TOP_DEPT_NO		�ŏ�ʕ���ԍ�
--  @RETURN		�I���R�[�h
-- *****************************************************************************
FUNCTION CHECK_IN_PROCESS_COST(
    I_JOB_ID                    IN NUMBER      --�W���u�h�c
    ,I_EXEC_JOB_ID              IN VARCHAR2    --���s���[�U�[�h�c
    ,I_TOP_DEPT_NO              IN VARCHAR2    --�ŏ�ʕ���ԍ�
)RETURN NUMBER
IS
    C_PROC_NAME		CONSTANT	VARCHAR2(30)
								:= 'CHECK_IN_PROCESS_COST';
	-- ���O�o�͗p����
	C_INFOLOG_NAME	CONSTANT	VARCHAR2(30)
								:= '�d�|�����f�[�^�G���[�`�F�b�N';

	V_ERR_MSG					VARCHAR2(4000); -- �G���[���b�Z�[�W

    -- �����J�E���g
    V_IN_COUNT                  NUMBER;         --�Ǎ�����
    V_ERR_COUNT                 NUMBER;       	--�G���[����
    V_ERR_FLG                   VARCHAR2(1);    --�G���[�t���O

    R_TYPE_MAST                             TYPE_MAST%ROWTYPE; --�敪�}�X�^���
	V_FINAN_YM								VARCHAR2(6); -- ��v�N��
	R_TR_COMMENCE_COST_WK					TR_COMMENCE_COST_WK%ROWTYPE; -- �d�|�������[�N�i���Ёj

	-- �i�P�j ���o�ΏۂƂȂ�d�|�������[�N���擾����i�������ׁj�B
	CURSOR CUR_TR_COMMENCE_COST_WK IS
	SELECT *
	  FROM TR_COMMENCE_COST_WK A
	 WHERE A.TOP_DEPT_NO = P_TOP_DEPT_NO
	 ORDER BY A.ID;

BEGIN

	-- ������
	V_END_CODE := CONST_BATCH_EXIT_CODE.C_NORMAL_EXIT;
	V_WARN_CNT := 0;			-- �x����������

	--����
	P_TOP_DEPT_NO := I_TOP_DEPT_NO;

	-- (1) �W���uID���擾
	V_JOB_ID := CMN.PRE_PROCESS(I_JOB_ID, I_EXEC_JOB_ID, C_PACKAGE_NAME);

	-- (2) �v���O�����J�n�������O�ɏo��
	CMN.INFO(V_JOB_ID
			,C_PACKAGE_NAME
			,C_INFOLOG_NAME || '���J�n���܂����B');

	--�i�R�j	��v�N�����擾����B
	V_FINAN_YM := CMN_OPER_ADMIN.GET_TOP_DEPT_FINAN_YM(P_TOP_DEPT_NO);

    -- �J�E���g�[���N���A
    V_IN_COUNT := 0;
    V_ERR_COUNT := 0;

	-- ���Ώۂ̃��R�[�h�i�����j�ɂ��āi�Q�j�`�i�S�j���A
	-- �Ǎ��񂾖��ׂ������Ȃ�܂ŌJ��Ԃ��s���B
	FOR R_TR_COMMENCE_COST_WK IN CUR_TR_COMMENCE_COST_WK LOOP
		-- �i�Q�j �d�|�������[�N�̓Ǎ��������J�E���g����B
		V_IN_COUNT := V_IN_COUNT + 1;

		-- �i�R�j �`�F�b�N���s���B
		-- �@ �G���[�t���O�i�ϐ��j
		V_ERR_FLG := CONST_FLAG.C_FALSE;

		-- �A �݌Ɏd���ʃ`�F�b�N
		IF NVL(R_TR_COMMENCE_COST_WK.COMMENCE_INV_JNL_TYPE, ' ')
				<> CONST_PGM_CMN.C_COMMENCE_INV_JNL_TYPE_PREV
			AND NVL(R_TR_COMMENCE_COST_WK.COMMENCE_INV_JNL_TYPE, ' ')
				<> CONST_PGM_CMN.C_COMMENCE_INV_JNL_TYPE_PRES
		THEN
			V_ERR_FLG := CONST_FLAG.C_TRUE;
			V_ERR_MSG := '�敪�}�X�^�����G���['
						|| '	���R�[�h�ԍ���' || V_IN_COUNT
						|| '	�݌Ɏd���ʋ敪��' || R_TR_COMMENCE_COST_WK.COMMENCE_INV_JNL_TYPE;
			CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_ERR_MSG);
		END IF;
		-- �B ��v�N���`�F�b�N
		IF V_FINAN_YM > R_TR_COMMENCE_COST_WK.FINAN_YM THEN
			V_ERR_FLG := CONST_FLAG.C_TRUE;
			V_ERR_MSG := '��v�N���G���['
						|| '	���R�[�h�ԍ���' || V_IN_COUNT
						|| '	��v�N����' || V_FINAN_YM
						|| '	��v�N����' || R_TR_COMMENCE_COST_WK.FINAN_YM;
			CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_ERR_MSG);
		END IF;

		-- �C �ԍ��敪�`�F�b�N
		BEGIN
			R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(
                                        CONST_CMNNO.C_RED_BLACK_TYPE,
                                        R_TR_COMMENCE_COST_WK.RED_BLACK_TYPE);
		EXCEPTION
			WHEN OTHERS THEN
                V_ERR_FLG := CONST_FLAG.C_TRUE;
                V_ERR_MSG := '�敪�}�X�^�����G���['
						|| '	���R�[�h�ԍ���' || V_IN_COUNT
						|| '	�ԍ��敪��' || R_TR_COMMENCE_COST_WK.RED_BLACK_TYPE;
                CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_ERR_MSG);
		END;

		-- �i�S�j �`�F�b�N������s���B
		IF V_ERR_FLG = CONST_FLAG.C_TRUE THEN
			V_ERR_COUNT := V_ERR_COUNT + 1;
		END IF;
	END LOOP;

	-- 3 �㏈��
	-- �i�P�j ��񃍃O���o�͂���
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '�d�|�������[�N�@�@�@�@�@�@�Ǎ�����: ' ||
        TO_CHAR(V_IN_COUNT,  '999,999')     || ' ��');
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '�d�|�������[�N�@�@�@�@�@�G���[����: ' ||
        TO_CHAR(V_ERR_COUNT,  '999,999')    || ' ��');


	-- �i�Q�j �G���[���� ��0 �Ȃ�A�G���[���b�Z�[�W���o�͂���B
	IF V_ERR_COUNT != 0 THEN
		V_ERR_MSG := '�d�|�����f�[�^�G���[�`�F�b�N�ɂăG���[���������Ă��܂��B';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
					C_PACKAGE_NAME, C_INFOLOG_NAME, NULL, NULL, V_ERR_MSG);
	END IF;
	-- �i�R�j �I�����O���o�͂���
	CMN.INFO(V_JOB_ID, C_PACKAGE_NAME, C_INFOLOG_NAME || '������I�����܂����B');

	-- �i�S�j �I����������
	CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);

    RETURN V_END_CODE;

EXCEPTION
	WHEN OTHERS THEN
        ROLLBACK;
		-- �ُ�I���R�[�h���Z�b�g
		V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		-- �v���O�����ُ�I���������O�ɏo��
		V_ERR_MSG := '�\�����ʃG���[���������܂����B';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						SQLCODE, SQLERRM, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
END CHECK_IN_PROCESS_COST;
-- *****************************************************************************
--�@�v���O������ : 190_20_21_02   ���i�݌ɕ\�������уf�[�^�G���[�`�F�b�N
--  @PARAM		I_JOB_ID			�W���uID
--  @PARAM		I_EXEC_JOB_ID		���s���[�UID
--  @PARAM		I_TOP_DEPT_NO		�ŏ�ʕ���ԍ�
--  @RETURN		�I���R�[�h
-- *****************************************************************************
FUNCTION CHECK_IN_PROCESS_COST_ACT(
    I_JOB_ID                    IN NUMBER      --�W���u�h�c
    ,I_EXEC_JOB_ID              IN VARCHAR2    --���s���[�U�[�h�c
    ,I_TOP_DEPT_NO              IN VARCHAR2    --�ŏ�ʕ���ԍ�
)RETURN NUMBER
IS
    C_PROC_NAME		CONSTANT	VARCHAR2(30)
								:= 'CHECK_IN_PROCESS_COST_ACT';
	-- ���O�o�͗p����
	C_INFOLOG_NAME	CONSTANT	VARCHAR2(50)
								:= '���i�݌ɕ\�������уf�[�^�G���[�`�F�b�N';

	V_ERR_MSG					VARCHAR2(4000); -- �G���[���b�Z�[�W

    -- �����J�E���g
    V_IN_COUNT                  NUMBER;         --�Ǎ�����
    V_ERR_COUNT                 NUMBER;       	--�G���[����
    V_ERR_FLG                   VARCHAR2(1);    --�G���[�t���O

    R_TYPE_MAST                             TYPE_MAST%ROWTYPE; --�敪�}�X�^���
	V_FINAN_YM								VARCHAR2(6); -- ��v�N��

	R_TR_PROD_INV_COST_ACT_WK					TR_PROD_INV_COST_ACT_WK%ROWTYPE; -- �d�|�������[�N�i���Ёj

-- �i�P�j ���o�ΏۂƂȂ鐻�i�݌ɕ\�������у��[�N���擾����i�������ׁj�B
	CURSOR CUR_TR_PROD_INV_COST_ACT_WK IS
	SELECT *
	  FROM TR_PROD_INV_COST_ACT_WK A
	 WHERE  A.TOP_DEPT_NO = P_TOP_DEPT_NO
	 ORDER BY A.TR_PROD_INV_COST_ACT_WK_ID;

BEGIN
	
	-- ������
	V_END_CODE := CONST_BATCH_EXIT_CODE.C_NORMAL_EXIT;
	V_WARN_CNT := 0;			-- �x����������
	--����
	P_TOP_DEPT_NO := I_TOP_DEPT_NO;

	-- (1) �W���uID���擾
	V_JOB_ID := CMN.PRE_PROCESS(I_JOB_ID, I_EXEC_JOB_ID, C_PACKAGE_NAME);

	-- (2) �v���O�����J�n�������O�ɏo��
	CMN.INFO(V_JOB_ID
			,C_PACKAGE_NAME
			,C_INFOLOG_NAME || '���J�n���܂����B');

	--�i�R�j	��v�N�����擾����B
	V_FINAN_YM := CMN_OPER_ADMIN.GET_TOP_DEPT_FINAN_YM(P_TOP_DEPT_NO);

    -- �J�E���g�[���N���A
    V_IN_COUNT := 0;
    V_ERR_COUNT := 0;

	-- ���Ώۂ̃��R�[�h�i�����j�ɂ��āi�Q�j�`�i�S�j���A
	-- �Ǎ��񂾖��ׂ������Ȃ�܂ŌJ��Ԃ��s���B
	FOR R_TR_PROD_INV_COST_ACT_WK IN CUR_TR_PROD_INV_COST_ACT_WK LOOP
		-- �i�Q�j ���i�݌ɕ\�������у��[�N�̓Ǎ��������J�E���g����B
		V_IN_COUNT := V_IN_COUNT + 1;

		-- �i�R�j �`�F�b�N���s���B
		-- �@ �G���[�t���O�i�ϐ��j
		V_ERR_FLG := CONST_FLAG.C_FALSE;
		
		-- �A ��v�N���`�F�b�N
		IF  V_FINAN_YM > R_TR_PROD_INV_COST_ACT_WK.FINAN_YM
		THEN
			V_ERR_FLG := CONST_FLAG.C_TRUE;
			V_ERR_MSG := '��v�N���G���['
						|| '	���R�[�h�ԍ���' || V_IN_COUNT
						|| '	�k�Q��v�N����' || V_FINAN_YM
						|| '	,��v�N����'    || R_TR_PROD_INV_COST_ACT_WK.FINAN_YM;
			CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_ERR_MSG);
		END IF;
		-- �B ���i�R�[�h�`�F�b�N
		/*IF GET_GOODS_MAST(V_IN_COUNT, R_TR_PROD_INV_COST_ACT_WK.GOODS_CODE) = 0
		THEN
            V_ERR_FLG := CONST_FLAG.C_TRUE;
			V_ERR_MSG := '���i�}�X�^�����G���['
						|| '	���R�[�h�ԍ���' || V_IN_COUNT
						|| '	�i�ڃR�[�h��'   || R_TR_PROD_INV_COST_ACT_WK.GOODS_CODE;
			CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_ERR_MSG);
		END IF;*/

		IF SUBSTR(R_TR_PROD_INV_COST_ACT_WK.GOODS_CODE, 0, 3) <> SUBSTR(P_TOP_DEPT_NO, 0, 3) 
		THEN
			-- �G���[�t���O
            V_ERR_FLG := CONST_FLAG.C_TRUE;
			V_ERR_MSG := '���i�R�[�h�i�擪�R�P�^�j�A���}�b�`�G���[�B' 					  ||
						'���R�[�h�ԍ���['		||	V_IN_COUNT								|| ']' ||
						'���i�R�[�h��['		 ||	R_TR_PROD_INV_COST_ACT_WK.GOODS_CODE	 || ']' ||
						'�ŏ�ʕ���ԍ���['	   || P_TOP_DEPT_NO				   			   || ']';
			CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_ERR_MSG);
		END IF;
		-- �C �e���i�R�[�h�`�F�b�N
		IF GET_GOODS_MAST(V_IN_COUNT, R_TR_PROD_INV_COST_ACT_WK.PARENT_GOODS_CODE) = 0
		THEN
            V_ERR_FLG := CONST_FLAG.C_TRUE;
			V_ERR_MSG := '���i�}�X�^�����G���['
						|| '	���R�[�h�ԍ���' || V_IN_COUNT
						|| '	�i�ڃR�[�h��'   || R_TR_PROD_INV_COST_ACT_WK.PARENT_GOODS_CODE;
			CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_ERR_MSG);
		END IF;

		IF SUBSTR(R_TR_PROD_INV_COST_ACT_WK.PARENT_GOODS_CODE, 0, 3) <> SUBSTR(P_TOP_DEPT_NO, 0, 3) THEN
			-- �G���[�t���O
            V_ERR_FLG := CONST_FLAG.C_TRUE;
			V_ERR_MSG := '���i�R�[�h�i�擪�R�P�^�j�A���}�b�`�G���[�B' 						  ||
						'���R�[�h�ԍ���['		||	V_IN_COUNT									|| ']' ||
						'���i�R�[�h��['		 ||	R_TR_PROD_INV_COST_ACT_WK.PARENT_GOODS_CODE	 || ']' ||
						'�ŏ�ʕ���ԍ���['	   || P_TOP_DEPT_NO				   				   || ']';
			CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_ERR_MSG);
		END IF;
		-- �D �i�ڎd��敪�`�F�b�N
		 BEGIN
                R_TYPE_MAST := CMN_TYPE_MAST.GET_TYPE_MAST(
                            CONST_CMNNO.C_GOODS_JNL_TYPE,
                            R_TR_PROD_INV_COST_ACT_WK.GOODS_JNL_TYPE);
            EXCEPTION
                WHEN OTHERS THEN	
                    V_ERR_MSG := '�敪�}�X�^�����G���[�B' 											  ||
                    			'���R�[�h�ԍ���['        || V_IN_COUNT                               || ']' ||
                   				'�i�ڎd��敪��['    	  || R_TR_PROD_INV_COST_ACT_WK.GOODS_JNL_TYPE || ']';
                    CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_ERR_MSG);
                    V_ERR_FLG :=  CONST_FLAG.C_TRUE;
            END;

		-- �i�S�j �`�F�b�N������s���B
		IF V_ERR_FLG = CONST_FLAG.C_TRUE THEN
			V_ERR_COUNT := V_ERR_COUNT + 1;
		END IF;
	END LOOP;

	-- 3 �㏈��
	-- �i�P�j ��񃍃O���o�͂���
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '���i�݌ɕ\�������с@�@�@�@�@�@�Ǎ�����: ' ||
        TO_CHAR(V_IN_COUNT,  '999,999')     || ' ��');
    CMN.INFO(V_JOB_ID,C_PACKAGE_NAME, '���i�݌ɕ\�������с@�@�@�@�@�G���[����: ' ||
        TO_CHAR(V_ERR_COUNT,  '999,999')    || ' ��');

	-- �i�Q�j �G���[���� ��0 �Ȃ�A�G���[���b�Z�[�W���o�͂���B
	IF V_ERR_COUNT <> 0 THEN
        ROLLBACK;
		-- �v���O�����ُ�I���������O�ɏo��
		V_ERR_MSG := '���i�݌ɕ\�������уf�[�^�G���[�`�F�b�N�ɂăG���[���������Ă��܂��B';
		CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
						C_PACKAGE_NAME, C_PROC_NAME,
						NULL, NULL, V_ERR_MSG);

        V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
        -- ��L���b�Z�[�W�o�͌�A�I����������B
		CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
    ELSE
        COMMIT;
        CMN.INFO(V_JOB_ID
				,C_PACKAGE_NAME
				,C_INFOLOG_NAME || '������I�����܂����B');
	END IF;

	-- �㏈��
	CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);

    RETURN V_END_CODE;

	EXCEPTION
		WHEN OTHERS THEN
            ROLLBACK;
            -- �ُ�I���R�[�h���Z�b�g
            V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
            -- �v���O�����ُ�I���������O�ɏo��
            V_ERR_MSG := '�\�����ʃG���[���������܂����B';
            CMN_EXCEPTION.RAISE_BAT_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                            C_PACKAGE_NAME, C_PROC_NAME,
                            SQLCODE, SQLERRM, V_ERR_MSG);

            V_END_CODE := CONST_BATCH_EXIT_CODE.C_ABORT_EXIT;
            CMN.POST_PROCESS(V_JOB_ID, C_PACKAGE_NAME, V_END_CODE);
        RETURN V_END_CODE;
END CHECK_IN_PROCESS_COST_ACT;

-- *************************************************************************
--  ������{�}�X�^����
--  @PARAM      I_COUNT		     1.�Ǎ�����
--  @PARAM      I_PARTNER_NO     2.�����ԍ�
--  @RETURN     ����
-- *************************************************************************
 FUNCTION GET_PARTNER(
	I_COUNT						IN	NUMBER
	,I_PARTNER_NO				IN	PARTNER_BASE_MAST.PARTNER_NO%TYPE
) RETURN NUMBER
IS
    C_PROC_NAME   CONSTANT VARCHAR2(30) := 'GET_PARTNER';
    V_MSG         VARCHAR2(4000);

	--����挏��
	V_COUNT		NUMBER(11,0);


BEGIN
	V_COUNT	:=	0;

    SELECT  COUNT(*)
       INTO V_COUNT
    FROM 	PARTNER_BASE_MAST
    WHERE 	PARTNER_NO = I_PARTNER_NO;

	IF V_COUNT = 0 THEN
        V_MSG := '������{�}�X�^�����G���[�B'     ||
        ' ���R�[�h�ԍ�=['   || I_COUNT      || ']'  ||
        ' �d����ԍ�=['     || I_PARTNER_NO || ']';

		-- ���O�o��
        CMN.ERROR(V_JOB_ID,C_PACKAGE_NAME ,NULL,V_MSG);
	END IF;

	RETURN V_COUNT;

EXCEPTION
    WHEN OTHERS THEN
        -- �v���O�����ُ�I���������O�ɏo��
        V_MSG := '������{�}�X�^�����G���[�B' ||
        ' �d����ԍ�=[' || I_PARTNER_NO         || ']';
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);
END GET_PARTNER;
-- *************************************************************************
--  V�����{�}�X�^������
--  @PARAM      I_COUNT              1.�Ǎ�����
--  @PARAM      I_DEPT_NO		     2.����ԍ�
--  @PARAM      I_PARAM_NAME         3.PARAM NAME TO DISPLAY ERROR LOG
--  @RETURN     ����
-- *************************************************************************
FUNCTION GET_V_DEPT_BASE_MAST(
    I_COUNT         IN	NUMBER                              --�Ǎ�����
    ,I_DEPT_NO      IN  V_DEPT_BASE_MAST.DEPT_NO%TYPE       --����ԍ�
    ,I_PARAM_NAME   IN  VARCHAR2                            --
) RETURN NUMBER
IS
    C_PROC_NAME   CONSTANT VARCHAR2(30) := 'GET_V_DEPT_BASE_MAST';
    V_MSG         VARCHAR2(4000);

	--����挏��
	V_COUNT		NUMBER(11,0);

BEGIN
    V_COUNT := 0;

    SELECT COUNT(*)
      INTO V_COUNT
      FROM V_DEPT_BASE_MAST
     WHERE DEPT_NO = I_DEPT_NO;

    IF V_COUNT = 0 THEN
        V_MSG := '�����{�}�X�^�����G���[�B'  ||
        ' ���R�[�h�ԍ���['                     || I_COUNT        || ']' ||
        ' ' || I_PARAM_NAME     || '��['       || I_DEPT_NO      || ']';

		-- ���O�o��
        CMN.ERROR(V_JOB_ID,C_PACKAGE_NAME ,NULL,V_MSG);
	END IF;

	RETURN V_COUNT;

EXCEPTION
    WHEN OTHERS THEN
        -- �v���O�����ُ�I���������O�ɏo��
        V_MSG := '�����{�}�X�^�����G���[�B'    ||
                ' ' || I_PARAM_NAME || '��['     || I_DEPT_NO      || ']';
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);

END GET_V_DEPT_BASE_MAST;

-- *************************************************************************
--  �Ј���{�}�X�^����
--  @PARAM      I_COUNT              1.�Ǎ�����
--  @PARAM      I_EMP_CODE		     2.�Ј��ԍ�
--  @RETURN     ����
-- *************************************************************************
FUNCTION GET_EMP_BASE_MAST(
    I_COUNT					    IN	NUMBER                           --�Ǎ�����
    ,I_EMP_CODE                 IN  EMP_BASE_MAST.EMP_CODE%TYPE     --�Ј��ԍ�
) RETURN NUMBER
IS
    C_PROC_NAME   CONSTANT VARCHAR2(30) := 'GET_EMP_BASE_MAST';
    V_MSG         VARCHAR2(4000);

	--����挏��
	V_COUNT		NUMBER(11,0);

BEGIN
    V_COUNT := 0;

    SELECT  COUNT(*)
       INTO V_COUNT
    FROM    EMP_BASE_MAST
    WHERE   EMP_CODE = I_EMP_CODE;

    IF V_COUNT = 0 THEN
        V_MSG := '�Ј���{�}�X�^�����G���[�B'       ||
        ' ���R�[�h�ԍ���['          || I_COUNT      || ']' ||
        ' �d���S���Ј��R�[�h=['     || I_EMP_CODE   || ']';
		-- ���O�o��
        CMN.ERROR(V_JOB_ID,C_PACKAGE_NAME ,NULL,V_MSG);
	END IF;

	RETURN V_COUNT;

EXCEPTION
    WHEN OTHERS THEN
        -- �v���O�����ُ�I���������O�ɏo��
        V_MSG := '�Ј���{�}�X�^�����G���[�B' ||
        ' �d���S���Ј��R�[�h=[' || I_EMP_CODE || ']';
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);

END GET_EMP_BASE_MAST;


-- *************************************************************************
--����摮���i�d����E���|��j��������
--  @PARAM      I_COUNT                     1.�Ǎ�����
--  @PARAM      I_PARTNER_NO		        2.�����ԍ�
--  @PARAM      I_PARTNER_ACCOUNT_NO        3.���������ԍ�
--  @RETURN     O_R_PARTNER_ATTRIBUTE_MAST	4.����摮���}�X�^
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

	--����摮���}�X�^���
	R_PARTNER_ATTRIBUTE_MAST			PARTNER_ATTRIBUTE_MAST%ROWTYPE;
BEGIN

	--������
	R_PARTNER_ATTRIBUTE_MAST := NULL;
	O_R_PARTNER_ATTRIBUTE_MAST := NULL;

	--�d���摮���}�X�^�����擾����
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

	--�d���摮���}�X�^���擾�ł��Ȃ������ꍇ�A
	--���|�摮���}�X�^�����擾����
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
        V_MSG := '����摮���i�d����E���|��j�����G���[�B' ||
        ' ���R�[�h�ԍ���['  || I_COUNT              || ']'  ||
        ' �����ԍ�=['     || I_PARTNER_NO         || ']'  ||
        ' ���������ԍ�=[' || I_PARTNER_ACCOUNT_NO || ']';
		-- ���O�o��
        CMN.ERROR(V_JOB_ID,C_PACKAGE_NAME ,NULL,V_MSG);
	END IF;

	--�A�E�g�p�����[�^�Ɏ擾�f�[�^��ݒ�
	O_R_PARTNER_ATTRIBUTE_MAST := R_PARTNER_ATTRIBUTE_MAST;

EXCEPTION
    WHEN OTHERS THEN
        -- �v���O�����ُ�I���������O�ɏo��
        V_MSG := '����摮���i�d����E���|��j�����G���[�B' ||
        ' �����ԍ�=['     || I_PARTNER_NO         || ']' ||
        ' ���������ԍ�=[' || I_PARTNER_ACCOUNT_NO || ']';
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);

END GET_PARTNER_ATTRIBUTE_MAST;

-- *************************************************************************
--  ����摮���i�x����j����
--  @PARAM      I_COUNT                     1.�Ǎ�����
--  @PARAM      I_PARTNER_NO		        2.�����ԍ�
--  @PARAM      I_PARTNER_ACCOUNT_NO        3.���������ԍ�
--  @RETURN     ����
-- *************************************************************************
FUNCTION GET_PAY_TO(
	I_COUNT						IN	NUMBER
	,I_PARTNER_NO				IN	PARTNER_ATTRIBUTE_MAST.PARTNER_NO%TYPE
    ,I_PARTNER_ACCOUNT_NO       IN  PARTNER_ATTRIBUTE_MAST.PARTNER_ACCOUNT_NO%TYPE
) RETURN NUMBER
IS
    C_PROC_NAME   CONSTANT VARCHAR2(30) := 'GET_PAY_TO';
    V_MSG         VARCHAR2(4000);

	--����挏��
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
        V_MSG := '����摮���i�x����j�����G���[�B' ||
        ' ���R�[�h�ԍ���['  || I_COUNT              || ']'  ||
        ' �x����ԍ�=['     || I_PARTNER_NO         || ']'  ||
        ' �x��������ԍ�=[' || I_PARTNER_ACCOUNT_NO || ']';
		-- ���O�o��
        CMN.ERROR(V_JOB_ID,C_PACKAGE_NAME ,NULL,V_MSG);
	END IF;

	RETURN V_COUNT;

EXCEPTION
    WHEN OTHERS THEN
        -- �v���O�����ُ�I���������O�ɏo��
        V_MSG := '����摮���i�x����j�����G���[�B' ||
        ' �����ԍ�=['     || I_PARTNER_NO         || ']' ||
        ' ���������ԍ�=[' || I_PARTNER_ACCOUNT_NO || ']';
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);
END GET_PAY_TO;

-- *************************************************************************
--  �d�c�h�R�[�h�敪�ϊ�(����)������
--  @PARAM      I_COUNT                     1.�Ǎ�����
--  @PARAM      I_TOP_DEPT_NO		        2.�ŏ�ʕ���ԍ�
--  @PARAM      I_EDI_DISTINCTION_TYPE      3.�d�c�h�A�g�掯�ʋ敪
--  @PARAM      I_COMMON_NO                 4.���ʔԍ�
--  @PARAM      I_CODE_TYPE_NO              5.�R�[�h�敪�ԍ�
--  @PARAM      I_OPER_START_DATE           6.�^�p�J�n���t
--  @PARAM      I_PARAM_NAME                7.PARAM NAME TO DISPLAY ERROR LOG
--  @RETURN     �d�c�h�R�[�h�敪�ϊ�(����)
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

	--�d�c�h�R�[�h�敪�ϊ�
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
        V_MSG := '�d�c�h�R�[�h�敪�ϊ�(����)�������G���[�B' ||
        ' ���R�[�h�ԍ���['      || I_COUNT          || '] ' ||
        I_PARAM_NAME || '=['    || I_CODE_TYPE_NO   || ']';

		-- ���O�o��
        CMN.ERROR(V_JOB_ID,C_PACKAGE_NAME ,NULL,V_MSG);

    WHEN OTHERS THEN
        -- �v���O�����ُ�I���������O�ɏo��
        V_MSG := '�d�c�h�R�[�h�敪�ϊ�(����)�������G���[�B '    ||
        I_PARAM_NAME || '=[' || I_CODE_TYPE_NO                  || ']';
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);
END GET_EDI_CODE_TYPE_CONV;

-- *************************************************************************
--  ��v�N���`�F�b�N
--  @PARAM      I_COUNT                     1.�Ǎ�����
--  @PARAM      I_FINAN_YM		            2.��v�N��
--  @PARAM      I_CHECKED_YM                3.�l�b��v�N��
--  @PARAM      I_PARAM_NAME                4.PARAM NAME TO DISPLAY ERROR LOG
--  @PARAM      I_O_ERR_FLG                 5.�G���[�t���O
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
        -- �G���[�t���O
        I_O_ERR_FLG := CONST_FLAG.C_TRUE;
        -- �G���[���b�Z�[�W�o��
        V_MSG := '��v�N���G���[�B'    ||
        ' ���R�[�h�ԍ���['             || I_COUNT       || ']' ||
        ' �k�Q��v�N����['             || I_FINAN_YM    || ']' ||
        ' ' || I_PARAM_NAME || '��['   || I_CHECKED_YM  || ']';
        CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
         -- �v���O�����ُ�I���������O�ɏo��
        V_MSG := '��v�N���G���[�B'         ||
        ' �k�Q��v�N����['             || I_FINAN_YM    || ']' ||
        ' ' || I_PARAM_NAME || '��['   || I_CHECKED_YM  || ']';
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);
END CHECK_FINAN_YM;

-- *************************************************************************
--  �݌Ɏ�ދ敪�`�F�b�N
--  @PARAM      I_COUNT                     1.�Ǎ�����
--  @PARAM      I_INVENT_KIND_TYPE          2.�݌Ɏ�ދ敪
--  @PARAM      I_O_ERR_FLG                 3.�G���[�t���O
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
        -- �G���[�t���O
        I_O_ERR_FLG := CONST_FLAG.C_TRUE;
        -- �G���[���b�Z�[�W�o��
        V_MSG := '�݌Ɏ�ދ敪�ΏۊO�G���[�B'       ||
        ' ���R�[�h�ԍ���[' || I_COUNT               || ']' ||
        ' �݌Ɏ�ދ敪��[' || I_INVENT_KIND_TYPE    || ']';
        CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
         -- �v���O�����ُ�I���������O�ɏo��
        V_MSG := '�݌Ɏ�ދ敪�ΏۊO�G���[�B'       ||
        ' �݌Ɏ�ދ敪��[' || I_INVENT_KIND_TYPE    || ']';
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);
END CHECK_INVENT_KIND_TYPE;

-- *************************************************************************
--  �݌Ɏd���ʃ`�F�b�N
--  @PARAM      I_COUNT                     1.�Ǎ�����
--  @PARAM      I_JNL_INVENT_KIND_TYPE      2.�݌Ɏd���ʋ敪
--  @PARAM      I_O_ERR_FLG                 3.�G���[�t���O
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
        -- �G���[�t���O
        I_O_ERR_FLG := CONST_FLAG.C_TRUE;
        -- �G���[���b�Z�[�W�o��
        V_MSG :='�敪�}�X�^�����G���[�B'                    ||
        ' ���R�[�h�ԍ���['      || I_COUNT                  || ']' ||
        ' �݌Ɏd���ʋ敪��['  || I_JNL_INVENT_KIND_TYPE   || ']';
        CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
         -- �v���O�����ُ�I���������O�ɏo��
        V_MSG :='�敪�}�X�^�����G���[�B'                    ||
        ' �݌Ɏd���ʋ敪��['  || I_JNL_INVENT_KIND_TYPE   || ']';
        CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, SQLERRM, V_MSG);
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);
END CHECK_INVENT_JNL_KIND_TYPE;

-- *************************************************************************
--  ���i�}�X�^������
--  @PARAM      I_COUNT              1.�Ǎ�����
--  @PARAM      I_GOODS_CODE		 2.����ԍ�
--  @RETURN     ����
-- *************************************************************************
FUNCTION GET_GOODS_MAST(

    I_COUNT                 IN              NUMBER
    ,I_GOODS_CODE           IN              VARCHAR2
)RETURN NUMBER
IS
    C_PROC_NAME   CONSTANT VARCHAR2(30) := 'GET_GOODS_MAST';
    V_MSG         VARCHAR2(4000);

	--����挏��
	V_COUNT		NUMBER(11,0);

BEGIN
    V_COUNT := 0;

    SELECT COUNT(*)
        INTO V_COUNT
    FROM GOODS_MAST
    WHERE GOODS_CODE = I_GOODS_CODE;

    IF V_COUNT = 0 THEN
        V_MSG := '���i�}�X�^�����G���[�B'          ||
        ' ���R�[�h�ԍ���['     || I_COUNT          || ']' ||
        ' ���i�R�[�h��['       || I_GOODS_CODE     || ']';

		-- ���O�o��
        CMN.ERROR(V_JOB_ID,C_PACKAGE_NAME ,NULL,V_MSG);
	END IF;

	RETURN V_COUNT;

EXCEPTION
    WHEN OTHERS THEN
        -- �v���O�����ُ�I���������O�ɏo��
        V_MSG := '���i�}�X�^�����G���[�B' ||
        ' ���i�R�[�h=[' || I_GOODS_CODE || ']';
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);

END GET_GOODS_MAST;

-- *************************************************************************
--  �q�Ƀ}�X�^������
--  @PARAM      I_COUNT              1.�Ǎ�����
--  @PARAM      I_TOP_DEPT_NO		 2.�ŏ�ʕ���ԍ�
--  @PARAM      I_WAREHOUSE_NO       3.�q�ɔԍ�
--  @PARAM      I_PLACE_CODE         4.�l�b�ꏊ�R�[�h
--  @RETURN     ����
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

	--����挏��
	V_COUNT		NUMBER(11,0);

BEGIN
    V_COUNT := 0;

     SELECT COUNT(*)
       INTO V_COUNT
       FROM WAREHOUSE_MAST
      WHERE TOP_DEPT_NO     = I_TOP_DEPT_NO
        AND WAREHOUSE_NO    = I_WAREHOUSE_NO;


    IF V_COUNT = 0 THEN
        V_MSG := '�q�Ƀ}�X�^�����G���[�B'          ||
        ' ���R�[�h�ԍ���['     || I_COUNT          || ']' ||
        ' ' || I_PARAM_NAME    || '��['            || I_PLACE_CODE     || ']' ||
        ' �q�ɔԍ���['         || I_WAREHOUSE_NO   || ']'  ;

		-- ���O�o��
        CMN.ERROR(V_JOB_ID,C_PACKAGE_NAME ,NULL,V_MSG);
	END IF;

	RETURN V_COUNT;

EXCEPTION
    WHEN OTHERS THEN
        -- �v���O�����ُ�I���������O�ɏo��
        V_MSG := '�q�Ƀ}�X�^�����G���[�B'          ||
        ' ' || I_PARAM_NAME    || '��['            || I_PLACE_CODE     || ']' ||
        ' �q�ɔԍ���['         || I_WAREHOUSE_NO   || ']'  ;
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);
END GET_WAREHOUSE;


-- *************************************************************************
--  �݌ɒu��}�X�^������
--  @PARAM      I_COUNT              1.�Ǎ�����
--  @PARAM      I_TOP_DEPT_NO         2.�ŏ�ʕ���ԍ�
--  @PARAM      I_WAREHOUSE_NO       3.�q�ɔԍ�
--  @PARAM      I_INVENT_PLACE_NO    4.�݌ɒu����ԍ�
--  @PARAM      I_PLACE_CODE         5.�l�b�ꏊ�R�[�h
--  @RETURN     ����
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

    --����挏��
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
        V_MSG := '�݌ɒu��}�X�^�����G���[�B'          ||
        ' ���R�[�h�ԍ���['     || I_COUNT          || ']' ||
        ' ' || I_PARAM_NAME    ||'��['             || I_PLACE_CODE     || ']' ||
        ' �q�ɔԍ���['         || I_WAREHOUSE_NO   || ']' ||
        ' �u��ԍ���['         || I_INVENT_PLACE_NO|| ']' ;

        -- ���O�o��
        CMN.ERROR(V_JOB_ID,C_PACKAGE_NAME ,NULL,V_MSG);
    END IF;

    RETURN V_COUNT;

EXCEPTION
    WHEN OTHERS THEN
        -- �v���O�����ُ�I���������O�ɏo��
        V_MSG := '�݌ɒu��}�X�^�����G���[�B'          ||
        ' ' || I_PARAM_NAME    ||'��['             || I_PLACE_CODE     || ']' ||
        ' �q�ɔԍ���['         || I_WAREHOUSE_NO   || ']' ||
        ' �u��ԍ���['         || I_INVENT_PLACE_NO|| ']' ;
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);
END GET_INVENT_PLACE;

-- *************************************************************************
--  �N�x�`�F�b�N
--  @PARAM      I_COUNT                 1.�Ǎ�����
--  @PARAM      I_FINAN_YEAR            2.��v�N�x
--  @PARAM      I_CHECKED_FINAN_YEAR    3.��v�N�x
--  @PARAM      I_O_ERR_FLG             4.�G���[�t���O
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
        -- �G���[�t���O
        I_O_ERR_FLG := CONST_FLAG.C_TRUE;
        -- �G���[���b�Z�[�W�o��
        V_MSG := '�N�x�G���[�B'    ||
        ' ���R�[�h�ԍ���['         || I_COUNT                || ']' ||
        ' �k�Q�N�x��['             || I_FINAN_YEAR           || ']' ||
        ' �l�b�N�x��['             || I_CHECKED_FINAN_YEAR   || ']';
        CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
         -- �v���O�����ُ�I���������O�ɏo��
        V_MSG := '�N�x�G���[�B'         ||
        ' �k�Q�N�x��['             || I_FINAN_YEAR           || ']' ||
        ' �l�b�N�x��['             || I_CHECKED_FINAN_YEAR   || ']';
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);
END CHECK_FINAN_YEAR;

-- *************************************************************************
--  �݌Ɍv�Z���@�敪�`�F�b�N
--  @PARAM      I_COUNT                 1.�Ǎ�����
--  @PARAM      I_INVENT_CALC_TYPE      2.�݌Ɍn�c���@�敪
--  @PARAM      I_O_ERR_FLG             3.�G���[�t���O
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
        -- �G���[�t���O
        I_O_ERR_FLG := CONST_FLAG.C_TRUE;
        -- �G���[���b�Z�[�W�o��
        V_MSG := '�݌Ɍv�Z���@�ΏۊO�G���[�B'    ||
        ' ���R�[�h�ԍ���['                 || I_COUNT              || ']' ||
        ' �݌Ɍv�Z���@�敪��['             || I_INVENT_CALC_TYPE   || ']';
        CMN.ERROR(V_JOB_ID, C_PACKAGE_NAME, NULL, V_MSG);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
         -- �v���O�����ُ�I���������O�ɏo��
        V_MSG := '�݌Ɍv�Z���@�ΏۊO�G���[�B'         ||
        ' �݌Ɍv�Z���@�敪��['             || I_INVENT_CALC_TYPE    || ']';
        CMN_EXCEPTION.RAISE_PROC_ERROR(V_JOB_ID, C_PROGRAM_NAME,
                                    C_PACKAGE_NAME, C_PROC_NAME,
                                    SQLCODE, SQLERRM, V_MSG);
END CHECK_INVENT_CALC_TYPE;

END "TR_MC_DATA_ERROR_CHECK";
