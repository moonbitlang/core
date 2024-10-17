from langchain_community.chat_models import ChatZhipuAI
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate


def read_coverage(moonbit_code, index, api_key):
    read_prompt = ChatPromptTemplate.from_template(
        """
        You are a highly skilled MoonBit engineer. Now you need to read in MoonBit code and the indices of uncovered code lines, 
        then identify and return the functions containing those uncovered lines.
        Input:
        MoonBit code: {moonbit_code}
        Indices of uncovered code lines: {index}
        Output request:
        Your output should only include the functions that contain the uncovered code. 
        Do not include any analysis process or any other statements in your output.
        """
    )

    read_llm = ChatZhipuAI(
        api_key=api_key, model="glm-4-0520", temperature=0.5
    )

    read_retriever_chain = read_prompt | read_llm | StrOutputParser()
    response = read_retriever_chain.invoke(
        {"moonbit_code": moonbit_code, "index": index}
    )
    return response



