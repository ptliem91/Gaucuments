CREATE OR REPLACE PACKAGE BODY "CMN_CREATE_MONEY_SCREEN_TEMP" AS
-- ****************************************************************************
--	$Id: PACKAGE.BODY.CMN_CREATE_MONEY_SCREEN_TEMP.pls 11863 2014-04-08 06:58:46Z hungmh $
--	�ڋq��			�F�O�J�Y�Ɗ������
--	�V�X�e����		�F�k�Q�v���W�F�N�g
--	�Ǝ햼			�F����
--	�v���O������ 	�F�����ꗗ�Ɖ�TEMP�쐬
--	All rights reserved, Copyright (c) MITANI SANGYO Co.,Ltd. 2008-
-- ****************************************************************************

-- ----------------------------------------------------------------------------
--	�萔
-- ----------------------------------------------------------------------------

	-- �v���O������
	C_PROGRAM_NAME	CONSTANT	VARCHAR2(100)	:=
												'�����ꗗ�Ɖ�TEMP�쐬';
	-- �p�b�P�[�W��
	C_PACKAGE_NAME	CONSTANT	VARCHAR2(30)	:= 'CMN_CREATE_MONEY_SCREEN_TEMP';

	LOGICAL_ERROR	EXCEPTION;				-- �_���G���[
	EXPECTED_ERROR	EXCEPTION;				-- �\�������G���[

-- ----------------------------------------------------------------------------
--	�L��ϐ�
-- ----------------------------------------------------------------------------

	-- �����i�[�p
	P_TOP_DEPT_NO				VARCHAR2(4000);	-- 1.�ŏ�ʕ���ԍ�
	P_MONEY_DATE_S				VARCHAR2(4000);	-- 2.�J�n�������t(YYYYMMDD)
	P_MONEY_DATE_E				VARCHAR2(4000);	-- 3.�I���������t(YYYYMMDD)
	P_DUE_DEPT_NO				VARCHAR2(4000);	-- 4.�S������ԍ�
	P_DUE_EMP_CODE         		VARCHAR2(4000);	-- 5.�S���Ј��R�[�h
	P_INVOICE_TO_NO				VARCHAR2(4000);	-- 6.������ԍ�
	P_INVOICE_TO_ACCO_NO		VARCHAR2(4000);	-- 7.����������ԍ�
	P_ACCOUNT_SUBJECT_CODE		VARCHAR2(4000);	-- 8.����ȖڃR�[�h
	P_DENOMINATION_TYPE			VARCHAR2(4000);	-- 9.����敪
	P_ADD_UP_FLG				VARCHAR2(4000);	--10.���������t���O
	P_PARTNER_UNASSIGN_FLG		VARCHAR2(4000);	--11.����斢���t���̂݃t���O
	P_DEPT_UNASSIGN_FLG         VARCHAR2(4000);	--12.���喢���t���̂݃t���O

	-- ���̑��L��ϐ�
	V_JOB_ID					NUMBER	:= NULL;	-- �W���uID
	V_INPUT_CNT					NUMBER	:= 0;		-- �擾����
	V_OUTPUT_CNT				NUMBER	:= 0;		-- �쐬����

	V_MONEY_ADD_UP_DETAIL_CNT				NUMBER	:= 0;		-- �����������ׂ̌���

	-- �������z��ދ敪(�萔��)
	C_MONEY_DIFF_SORT_TYPE_FEES	CONSTANT	VARCHAR2(4) := '0001';

-- ----------------------------------------------------------------------------
--	�T�u�v���O�����錾
-- ----------------------------------------------------------------------------

-- �����ꗗ���\�z����
PROCEDURE CREATE_MONEY_SCREEN_TEMP;

--�J�[�\����`�p���ISQL�������g�ݗ��Ă�
FUNCTION EDIT_SCREEN_SQL RETURN VARCHAR2;

-- ���̖|����s��
PROCEDURE UPDATE_NAMES_FOR_SCR(
	IO_R_TEMP				IN OUT NOCOPY MONEY_SCREEN_TEMP%ROWTYPE
);

--	�������z���擾���A�������z�E�������z����ł�ҏW����
PROCEDURE GET_MONEY_DIFF (
	IO_R_TEMP					IN OUT	MONEY_SCREEN_TEMP%ROWTYPE
	);

--  �����������ׂ��擾����
PROCEDURE GET_MONEY_ADD_UP_DETAIL(
	I_MONEY_ID				IN	MONEY_ADD_UP_DETAIL.MONEY_ID%TYPE
	,O_FINAN_LINKED_FLG		OUT NOCOPY MONEY_ADD_UP_DETAIL.FINAN_LINKED_FLG%TYPE
	);

--  ���������֘A���擾���A�����t���O��ҏW����
PROCEDURE EDIT_ADDUP_FLG(
	IO_R_TEMP					IN OUT	MONEY_SCREEN_TEMP%ROWTYPE
	);

-- ----------------------------------------------------------------------------
--	�T�u�v���O�����{��
-- ----------------------------------------------------------------------------

-- ****************************************************************************
--	�����ꗗ�Ɖ�TEMP�쐬
--	���̃v���V�W���́AJava�A�v���P�[�V��������Ă΂�邱�Ƃ�O��Ƃ��Ă��܂��B
--	�g�����U�N�V�����Ǘ��͌Ăяo�����ōs���Ă��������B
--
--	��������A�ꎞ�\(�����ꗗ�Ɖ�TEMP)�̃f�[�^���쐬����
--	�܂��A�e���z��ҏW���邽�߁A�������z�A�����������ׂ���������B
--
-- @PARAM	I_TOP_DEPT_NO			�ŏ�ʕ���ԍ��i�K�{�j
-- @PARAM	I_MONEY_DATE_S			�J�n�������t�i�K�{�j
-- @PARAM	I_MONEY_DATE_E			�I���������t�i�K�{�j
-- @PARAM	I_DUE_DEPT_NO			�S������ԍ�
-- @PARAM	I_DUE_EMP_CODE			�S���Ј��R�[�h
-- @PARAM	I_INVOICE_TO_NO			������ԍ�
-- @PARAM	I_INVOICE_TO_ACCO_NO	����������ԍ�
-- @PARAM	I_ACCOUNT_SUBJECT_CODE	����ȖڃR�[�h
-- @PARAM	I_DENOMINATION_TYPE		����敪
-- @PARAM	I_ADD_UP_FLG			���������t���O
--									(TRUE:������ FALSE:������ NULL:�����ɂ��Ȃ�)
-- @PARAM	I_PARTNER_UNASSIGN_FLG	����斢���t���̂݃t���O
--									(TRUE:����斢���t���̂� FALSE:�����ɂ��Ȃ�)
-- @PARAM	I_DEPT_UNASSIGN_FLG     ���喢���t���̂݃t���O
--                                  (TRUE:���喢���t���̂� FALSE:�����ɂ��Ȃ�)
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

	V_MSG						VARCHAR2(4000);		-- �G���[���b�Z�[�W

BEGIN

	-- ����������
	V_INPUT_CNT := 0;
	V_OUTPUT_CNT := 0;

	-- �W���uID���擾�i�O���[�o���ҏW�Ɋi�[�j
	V_JOB_ID := CMN.GET_JOB_ID;

	-- �v���O�����J�n�������O�ɏo��
	CMN.DEBUG (V_JOB_ID, C_PACKAGE_NAME, '�J�n�F�y' || C_PROGRAM_NAME || '�z');

	-- �p�����^��ϐ��Ɋi�[
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

	-- �p�����^�\���i�f�o�b�O�p�j
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'�ŏ�ʕ���ԍ��@�@�@�@�@ (' || P_TOP_DEPT_NO || ')');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'�J�n�������t(YYYYMMDD)   (' || P_MONEY_DATE_S || ')');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'�I���������t(YYYYMMDD)   (' || P_MONEY_DATE_E || ')');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'�S������ԍ��@�@�@    �@ (' || P_DUE_DEPT_NO || ')');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'�S���Ј��R�[�h�@�@�@�@   (' || P_DUE_EMP_CODE || ')');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'������ԍ�               (' || P_INVOICE_TO_NO || ')');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'����������ԍ��@�@�@�@�@ (' || P_INVOICE_TO_ACCO_NO || ')');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'����ȖڃR�[�h�@�@�@     (' || P_ACCOUNT_SUBJECT_CODE || ')');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'����敪�@�@�@�@�@�@     (' || P_DENOMINATION_TYPE || ')');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'���������t���O�@         (' || P_ADD_UP_FLG || ')');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'����斢���t���̂݃t���O (' || P_PARTNER_UNASSIGN_FLG || ')');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME,
		'���喢���t���̂݃t���O   (' || P_DEPT_UNASSIGN_FLG || ')');

	-- �����ꗗ�Ɖ�TEMP���\�z����
	CREATE_MONEY_SCREEN_TEMP;

	-- �������O�\��
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME, '�Ǎ����� : ' ||
			TO_CHAR(V_INPUT_CNT,  '999,999') || ' ��');
	CMN.DEBUG(V_JOB_ID,C_PACKAGE_NAME, '�o�͌��� : ' ||
			TO_CHAR(V_OUTPUT_CNT,  '999,999') || ' ��');

	-- �v���O�����I���������O�ɏo��
	CMN.DEBUG (V_JOB_ID, C_PACKAGE_NAME, '�I���F�y' || C_PROGRAM_NAME || '�z');

EXCEPTION
	WHEN OTHERS THEN
		V_MSG		:= '�ُ�I�����܂����B';
		CMN_EXCEPTION.RAISE_APP_ERROR (
				 V_JOB_ID, C_PROGRAM_NAME, C_PACKAGE_NAME
				,C_PROC_NAME, SQLCODE, SQLERRM
				,V_MSG
		);
END CREATE_MONEY_SCREEN_TEMP;

-- ****************************************************************************
--	�����ꗗ�Ɖ�TEMP���\�z����
--	@PARAM	�Ȃ�
-- ****************************************************************************
PROCEDURE CREATE_MONEY_SCREEN_TEMP
IS

	C_PROC_NAME		CONSTANT	VARCHAR2(30)	:=
											'CREATE_MONEY_SCREEN_TEMP';
	V_MSG						VARCHAR2(4000);		-- �G���[���b�Z�[�W

	V_SQL						VARCHAR2(32767);	-- ���ISQL�ҏW�p

	-- �����ꗗ�����p�J�[�\��
	TYPE CUR_SCREEN_TYPE		IS REF CURSOR;
	CUR_MONEY_SC				CUR_SCREEN_TYPE;

	-- �����ꗗ�Ɖ�TEMP���R�[�h
	R_TEMP						MONEY_SCREEN_TEMP%ROWTYPE;

BEGIN

	-- ���ISQL���g�p���ăJ�[�\�����[�v
	V_SQL := EDIT_SCREEN_SQL;
	OPEN CUR_MONEY_SC FOR V_SQL;

	LOOP

		-- ������
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

		-- �擾�����J�E���g�A�b�v
		V_INPUT_CNT := V_INPUT_CNT + 1;

		-- �����������ׂ��擾����
		GET_MONEY_ADD_UP_DETAIL(R_TEMP.MONEY_ID, R_TEMP.FINAN_LINKED_FLG);

		-- �������z�Ǝ萔�����擾����
		GET_MONEY_DIFF(R_TEMP);

		-- ���������֘A���擾���A�����t���O��ҏW����
		EDIT_ADDUP_FLG(R_TEMP);

		-- �ȉ��̏ꍇ�A�����ꗗ�Ɖ�TEMP���쐬����
		-- �p�����^.���������׸ށ�NULL
		-- �܂��� (�����.���������׸ށ�TRUE(������) ���� �����������ׂ��擾��)
		-- �܂��� (�����.���������׸ށ�FALSE(������) ���� �����������ׂ��擾�s��)
		IF P_ADD_UP_FLG IS NULL OR P_ADD_UP_FLG = R_TEMP.ADD_UP_FLG THEN

			-- ID
			R_TEMP.ID := DM_MONEY_SCREEN_TEMP.GET_ID;
			-- ���������z
			R_TEMP.ADD_UP_AMOUNT := 0;

			-- �e��}�X�^���疼�̂�|�󂷂�
			UPDATE_NAMES_FOR_SCR(R_TEMP);

			-- �f�[�^�ǉ�
			DM_MONEY_SCREEN_TEMP.INSERT_ROW(R_TEMP);

			-- �쐬�����J�E���g�A�b�v
			V_OUTPUT_CNT := V_OUTPUT_CNT + 1;

		END IF;
	END LOOP;

	CLOSE CUR_MONEY_SC;

EXCEPTION
	WHEN OTHERS THEN
		V_MSG		:= '�����ꗗ�Ɖ�TEMP�\�z�Ɏ��s���܂����B';
		CMN_EXCEPTION.RAISE_PROC_ERROR (
				 V_JOB_ID, C_PROGRAM_NAME, C_PACKAGE_NAME
				,C_PROC_NAME, SQLCODE, SQLERRM
				,V_MSG
		);
END CREATE_MONEY_SCREEN_TEMP;

-- *************************************************************************
--	 �J�[�\����`�p���ISQL�������g�ݗ��Ă�
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
	-- �ŏ�ʕ���ԍ�
	V_SQL := V_SQL || ' WHERE TOP_DEPT_NO = ' || CMN_SQL_UTIL.SQ(P_TOP_DEPT_NO);
	-- �J�n�������t�A�I���������t
	V_SQL := V_SQL || ' AND TRADE_DATE >= ' || CMN_SQL_UTIL.V2D(P_MONEY_DATE_S);
	V_SQL := V_SQL || ' AND TRADE_DATE <= ' || CMN_SQL_UTIL.V2D(P_MONEY_DATE_E);
	-- �폜�t���O
	V_SQL := V_SQL || ' AND DELETE_FLG = ' || CMN_SQL_UTIL.SQ(CONST_FLAG.C_FALSE);

	-- �S������ԍ�
	IF P_DUE_DEPT_NO IS NOT NULL THEN
		V_SQL := V_SQL || ' AND DUE_DEPT_NO = ' || CMN_SQL_UTIL.SQ(P_DUE_DEPT_NO);
	END IF;
	-- ������ԍ�
	IF P_INVOICE_TO_NO IS NOT NULL THEN
		V_SQL := V_SQL || ' AND INVOICE_TO_NO = '
							|| CMN_SQL_UTIL.SQ(P_INVOICE_TO_NO);
	END IF;
	-- ����������ԍ�
	IF P_INVOICE_TO_ACCO_NO IS NOT NULL THEN
		V_SQL := V_SQL || ' AND INVOICE_TO_ACCOUNT_NO = '
							|| CMN_SQL_UTIL.SQ(P_INVOICE_TO_ACCO_NO);
	END IF;
	-- ����ȖڃR�[�h
	IF P_ACCOUNT_SUBJECT_CODE IS NOT NULL THEN
		V_SQL := V_SQL || ' AND ACCOUNT_SUBJECT_CODE = '
							|| CMN_SQL_UTIL.SQ(P_ACCOUNT_SUBJECT_CODE);
	END IF;
	-- ����敪
	IF P_DENOMINATION_TYPE IS NOT NULL THEN
		V_SQL := V_SQL || ' AND DENOMINATION_TYPE = '
			|| CMN_SQL_UTIL.SQ(P_DENOMINATION_TYPE);
	END IF;
	-- ����斢���t���̂݃t���O
	IF P_PARTNER_UNASSIGN_FLG = CONST_FLAG.C_TRUE THEN
		V_SQL := V_SQL || ' AND UNCONFIRM_INVOICE_TO_FLG = '
							|| CMN_SQL_UTIL.SQ(CONST_FLAG.C_TRUE);
	END IF;

	-- ���喢���t���̂݃t���O
	IF P_DEPT_UNASSIGN_FLG = CONST_FLAG.C_TRUE THEN
		V_SQL := V_SQL || ' AND UNCONFIRM_DEPT_NO_FLG = '
							|| CMN_SQL_UTIL.SQ(CONST_FLAG.C_TRUE);
	END IF;

	-- ���я�
	V_SQL := V_SQL || ' ORDER BY INVOICE_TO_NO';
	V_SQL := V_SQL || ',INVOICE_TO_ACCOUNT_NO';
	V_SQL := V_SQL || ',TRADE_DATE';
	V_SQL := V_SQL || ',DENOMINATION_TYPE';

	RETURN V_SQL;

EXCEPTION
	WHEN OTHERS THEN
			V_MSG := 'SQL�̕ҏW�Ɏ��s���܂����B';
			CMN_EXCEPTION.RAISE_PROC_ERROR (
							 V_JOB_ID, C_PROGRAM_NAME, C_PACKAGE_NAME
							,C_PROC_NAME, SQLCODE, SQLERRM
							,V_MSG
			);
END EDIT_SCREEN_SQL;

-- ****************************************************************************
--	���̖|����s��
--	@PARAM	�Ȃ�
-- ****************************************************************************
PROCEDURE UPDATE_NAMES_FOR_SCR(
	IO_R_TEMP				IN OUT NOCOPY MONEY_SCREEN_TEMP%ROWTYPE
)
IS
	C_PROC_NAME		CONSTANT	VARCHAR2(30)	:= 'UPDATE_NAMES_FOR_SCR';
	V_MSG						VARCHAR2(4000);		-- �G���[���b�Z�[�W

	R_PARTNER_BASE_MAST		PARTNER_BASE_MAST%ROWTYPE;--�����}�X�^
	R_PARTNER_ACCO_MAST		PARTNER_ACCO_MAST%ROWTYPE;--���������}�X�^
	R_DEPT_BASE_MAST		DEPT_BASE_MAST%ROWTYPE;--�����{�}�X�^
	R_EMP_BASE_MAST			EMP_BASE_MAST%ROWTYPE;--�Ј���{�}�X�^
	R_ACCOUNT_SUBJECT_MAST	ACCOUNT_SUBJECT_MAST%ROWTYPE;--����Ȗڃ}�X�^
	R_SUBSIDY_SUBJECT_MAST	SUBSIDY_SUBJECT_MAST%ROWTYPE;--�⏕����Ȗڃ}�X�^
	R_TYPE_MAST				TYPE_MAST%ROWTYPE;--�敪�}�X�^

BEGIN

    IF IO_R_TEMP.INVOICE_TO_NO IS NOT NULL THEN
        -- �����於��|�󂷂�
        DM_PARTNER_BASE_MAST.GET_BY_PK(
                IO_R_TEMP.INVOICE_TO_NO
                ,R_PARTNER_BASE_MAST
        );
        IO_R_TEMP.INVOICE_TO_ABBR := R_PARTNER_BASE_MAST.PARTNER_ABBR;
    
        IF IO_R_TEMP.INVOICE_TO_ACCOUNT_NO IS NOT NULL THEN
            -- �������������|�󂷂�
            DM_PARTNER_ACCO_MAST.GET_BY_LK(
                    IO_R_TEMP.INVOICE_TO_NO
                    ,IO_R_TEMP.INVOICE_TO_ACCOUNT_NO
                    ,R_PARTNER_ACCO_MAST
            );
            IO_R_TEMP.INVOICE_TO_ACCOUNT_NAME := R_PARTNER_ACCO_MAST.PARTNER_ACCO_NAME;
        END IF;
    END IF;

    IF IO_R_TEMP.DUE_DEPT_NO IS NOT NULL THEN
        -- ���喼��|�󂷂�
        R_DEPT_BASE_MAST := CMN_ORGANIZATION.GET_DEPT_BY_DATE(
                IO_R_TEMP.TRADE_DATE
                ,IO_R_TEMP.DUE_DEPT_NO
        );
        IO_R_TEMP.DUE_DEPT_ABBR := R_DEPT_BASE_MAST.DEPT_ABBR;
    END IF;

    IF IO_R_TEMP.DUE_EMP_CODE IS NOT NULL THEN
        -- �Ј�����|�󂷂�
        DM_EMP_BASE_MAST.GET_BY_PK(
                IO_R_TEMP.DUE_EMP_CODE
                ,R_EMP_BASE_MAST
        );
        IO_R_TEMP.DUE_EMP_NAME := R_EMP_BASE_MAST.EMP_NAME;
    END IF;

    IF IO_R_TEMP.DENOMINATION_TYPE IS NOT NULL THEN
        -- �敪����|�󂷂�
        R_TYPE_MAST :=	CMN_TYPE_MAST.GET_TYPE_MAST(
                CONST_CMNNO.C_DENOMINATION_TYPE
                ,IO_R_TEMP.DENOMINATION_TYPE
        );
        IO_R_TEMP.DENOMINATION_ABBR := R_TYPE_MAST.TYPE_ABBR;
    END IF;

    IF IO_R_TEMP.ACCOUNT_SUBJECT_CODE IS NOT NULL THEN
        -- ����Ȗږ���|�󂷂�
        DM_ACCOUNT_SUBJECT_MAST.GET_BY_PK(
                IO_R_TEMP.ACCOUNT_SUBJECT_CODE
                ,R_ACCOUNT_SUBJECT_MAST
        );
        IO_R_TEMP.ACCOUNT_SUBJECT_NAME := R_ACCOUNT_SUBJECT_MAST.ACCOUNT_SUBJECT_NAME;
    
        IF IO_R_TEMP.SUBSIDY_SUBJECT_CODE IS NOT NULL THEN
            -- �⏕����Ȗږ���|�󂷂�
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
		V_MSG		:= '���̖|��Ɏ��s���܂����B';
		CMN_EXCEPTION.RAISE_PROC_ERROR (
				 V_JOB_ID, C_PROGRAM_NAME, C_PACKAGE_NAME
				,C_PROC_NAME, SQLCODE, SQLERRM
				,V_MSG
		);

END UPDATE_NAMES_FOR_SCR;

-- ****************************************************************************
--	�������z���擾���A�������z�E�������z����ł�ҏW����
--	@PARAM	IO_R_TEMP				�����ꗗ�Ɖ�TEMP
--	@RETURN	�Ȃ�
-- ****************************************************************************
PROCEDURE GET_MONEY_DIFF (
	IO_R_TEMP					IN OUT	MONEY_SCREEN_TEMP%ROWTYPE
	)
IS
	C_PROC_NAME		CONSTANT	VARCHAR2(30)	:= 'GET_MONEY_DIFF';
	V_MSG						VARCHAR2(4000);		-- �G���[���b�Z�[�W
	V_SQL						VARCHAR2(4000);		-- ���ISQL�p

BEGIN

	BEGIN
		-- �������z�A�������z����ł��擾����
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
		-- �萔���A�萔���Ŋz���擾����(���������ɂ�ǉ����Ď擾����)
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
		V_MSG := '�������z�����G���[ ����ID�F' || IO_R_TEMP.MONEY_ID;
		CMN_EXCEPTION.RAISE_PROC_ERROR (
				 V_JOB_ID, C_PROGRAM_NAME, C_PACKAGE_NAME
				,C_PROC_NAME, SQLCODE, SQLERRM
				,V_MSG
		);
	WHEN OTHERS THEN
		V_MSG := '�������z�����G���[ ����ID�F' || IO_R_TEMP.MONEY_ID;
		CMN_EXCEPTION.RAISE_PROC_ERROR (
				 V_JOB_ID, C_PROGRAM_NAME, C_PACKAGE_NAME
				,C_PROC_NAME, SQLCODE, SQLERRM
				,V_MSG
		);

END GET_MONEY_DIFF;

-- *****************************************************************************
--  �����������ׂ��擾����
--  @PARAM		I_MONEY_ID			����ID
--  @PARAM		O_FINAN_LINKED_FLG	��v�A�g�σt���O
-- *****************************************************************************
PROCEDURE GET_MONEY_ADD_UP_DETAIL(
	I_MONEY_ID				IN	MONEY_ADD_UP_DETAIL.MONEY_ID%TYPE
	,O_FINAN_LINKED_FLG		OUT NOCOPY MONEY_ADD_UP_DETAIL.FINAN_LINKED_FLG%TYPE
)
IS

	C_PROC_NAME	CONSTANT		VARCHAR2(30)	:= 'GET_MONEY_ADD_UP_DETAIL';
	V_MSG						VARCHAR2(4000);		-- �G���[���b�Z�[�W
	V_COUNT					NUMBER := 0;			-- ���������֘A�̌���

BEGIN

	-- ������
	O_FINAN_LINKED_FLG := CONST_FLAG.C_FALSE;

	-- ���������֘A�̔���p
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
		-- �擾�ł����ꍇ�A�����ςƔ��肷��
		O_FINAN_LINKED_FLG := CONST_FLAG.C_TRUE;
	END IF;

EXCEPTION
	WHEN OTHERS THEN
		-- APPLICATION_ERROR��RAISE����B
		V_MSG := '�����������׍����G���['
					|| ' ����ID:' || I_MONEY_ID;
		CMN_EXCEPTION.RAISE_PROC_ERROR (
				 V_JOB_ID, C_PROGRAM_NAME, C_PACKAGE_NAME
				,C_PROC_NAME, SQLCODE, SQLERRM
				,V_MSG
		);

END GET_MONEY_ADD_UP_DETAIL;

-- *****************************************************************************
--  ���������֘A���擾���A�����t���O��ҏW����
--	@PARAM	IO_R_TEMP				�����ꗗ�Ɖ�TEMP
-- *****************************************************************************
PROCEDURE EDIT_ADDUP_FLG(
	IO_R_TEMP					IN OUT	MONEY_SCREEN_TEMP%ROWTYPE
)
IS

	C_PROC_NAME	CONSTANT		VARCHAR2(30)	:= 'EDIT_ADDUP_FLG';
	V_MSG						VARCHAR2(4000);		-- �G���[���b�Z�[�W
	V_SUM_AMOUNT				NUMBER := 0;			-- �W�v���z
	V_CNT_MONEY_ADD_UP_REL	NUMBER := 0;			-- ���������֘A
BEGIN
	-- ���������֘A�̌������J�E���g����
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
		-- APPLICATION_ERROR��RAISE����B
		V_MSG := '���������֘A�����G���['
					|| ' ����ID:' || IO_R_TEMP.MONEY_ID;
		CMN_EXCEPTION.RAISE_PROC_ERROR (
				 V_JOB_ID, C_PROGRAM_NAME, C_PACKAGE_NAME
				,C_PROC_NAME, SQLCODE, SQLERRM
				,V_MSG
		);

END EDIT_ADDUP_FLG;

END "CMN_CREATE_MONEY_SCREEN_TEMP";
