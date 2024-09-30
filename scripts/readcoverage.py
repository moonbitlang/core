from langchain_community.chat_models import ChatZhipuAI
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate

def read_coverage(moonbit_code, index, api_key):
    read_prompt = ChatPromptTemplate.from_template(
        """你是一位技术高超的moonbit工程师，现在你需要读入moonbit语言的代码以及测试未覆盖代码行数的索引
        根据索引找出测试未覆盖的代码并返回该行代码所在函数的函数
        需要读入的MoonBit代码：{moonbit_code}，未覆盖代码行数的索引：{index}
        注意，你的输出中只需要包含未覆盖的函数，不需要包含分析过程和任何其他语句。
        """
    )

    read_llm = ChatZhipuAI(
        api_key=api_key,
        model="glm-4-plus",
        temperature=0.5,
        max_tokens=2048
    )

    read_retriever_chain = (
        read_prompt
        | read_llm
        | StrOutputParser()
    )
    response = read_retriever_chain.invoke({
        "moonbit_code": moonbit_code,
         "index": index
    })
    return response





